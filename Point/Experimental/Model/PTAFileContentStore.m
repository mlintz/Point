//
//  PTAFileContentStore.m
//  Point
//
//  Created by Mikey Lintz on 1/1/15.
//  Copyright (c) 2015 Mikey Lintz. All rights reserved.
//

#import "PTAFileContentStore.h"

#import "PTAFileOperation.h"
#import "PTAFileOperationAggregator.h"

NSString * const kOperationAggregatorKey = @"PTAFileContentStore.operationMap";

@implementation PTAFileContentStore {
  NSOperationQueue *_operationQueue;
  PTAFileOperationAggregator *_operationAggregator;
  NSMutableDictionary *_filesMap;  // DBPath -> DBFile
}

- (instancetype)initWithQueue:(NSOperationQueue *)queue {
  NSParameterAssert(queue);
  self = [super init];
  if (self) {
    _operationQueue = queue;
    _operationAggregator = [PTAFileOperationAggregator aggregator];
  }
  return self;
}

- (instancetype)init {
  [self doesNotRecognizeSelector:_cmd];
  return nil;
}

- (void)savePendingOperationsToDefaults:(NSUserDefaults *)userDefaults {
  NSParameterAssert(userDefaults);
  NSData *archivedAggregator = [NSKeyedArchiver archivedDataWithRootObject:_operationAggregator];
  [userDefaults setObject:archivedAggregator forKey:kOperationAggregatorKey];
  [userDefaults synchronize];
}

- (void)loadPendingOperationsFromDefaults:(NSUserDefaults *)userDefaults {
  NSParameterAssert(userDefaults);
  NSData *archivedAggregator = [userDefaults dataForKey:kOperationAggregatorKey];
  PTAFileOperationAggregator *aggregator =
      [NSKeyedUnarchiver unarchiveObjectWithData:archivedAggregator];
  [_operationQueue addOperationWithBlock:^{
    _operationAggregator = aggregator ?: [PTAFileOperationAggregator aggregator];
  }];
}

- (void)addFile:(DBFile *)file {
  NSParameterAssert(file);

  __weak id weakSelf = self;
  void(^updateFileIfNecessary)() = ^() {
    PTAFileContentStore *strongSelf = weakSelf;
    if (strongSelf
        && [strongSelf shouldUpdateFile:file]
        && [strongSelf->_operationAggregator hasOperationForFileAtPath:file.info.path]) {
      [strongSelf safeApplyOperationsToFile:file];
    }
  };

  [_operationQueue addOperationWithBlock:^{
    _filesMap[file.info.path] = file;
    updateFileIfNecessary();
    NSOperationQueue *operationQueue = _operationQueue;
    [file addObserver:self block:^{
      [operationQueue addOperationWithBlock:updateFileIfNecessary];
    }];
  }];
}

- (void)removeFile:(DBFile *)file {
  NSParameterAssert(file);

  [file removeObserver:self];
  [_operationQueue addOperationWithBlock:^{
    [_filesMap removeObjectForKey:file.info.path];
  }];
}

- (void)applyOperation:(id<PTAFileOperation>)operation forFileAtPath:(DBPath *)path {
  NSParameterAssert(operation);
  NSParameterAssert(path);
  [_operationQueue addOperationWithBlock:^{
    DBFile *file = _filesMap[path];
    NSAssert(file, nil);
    if (![self shouldUpdateFile:file] || [_operationAggregator hasOperationForFileAtPath:path]) {
      [_operationAggregator addOperation:operation forFileAtPath:path];
      return;
    }
    NSError *error;
    NSString *originalContents = [file readString:&error];
    NSAssert(!error, nil);
    NSString *newContents = [operation contentByApplyingOperationToContent:originalContents];
    [file writeString:newContents error:&error];
    NSAssert(!error, nil);
  }];
}

- (void)readContentsOfFile:(DBPath *)path
                   success:(void (^)(DBPath *path, NSString *contents))success
                   failure:(void (^)(NSError *error))failure {
  NSParameterAssert(path);
  [_operationQueue addOperationWithBlock:^{
    DBFile *file = _filesMap[path];
    NSAssert(file, nil);
    if (!file.status.cached) {
      if (success) {
        dispatch_async(dispatch_get_main_queue(), ^{
          success(path, @"");
        });
      }
      return;
    }
    NSError *error;
    NSString *originalContents = [file readString:&error];
    if (error) {
      if (failure) {
        dispatch_async(dispatch_get_main_queue(), ^{
          failure(error);
        });
      }
      return;
    }
    NSString *newContents = originalContents;
    if ([_operationAggregator hasOperationForFileAtPath:path]) {
      newContents = [_operationAggregator string:newContents withOperationsAppliedForPath:path];
    }
    if (success) {
      dispatch_async(dispatch_get_main_queue(), ^{
        success(path, newContents);
      });
    }
  }];
}

#pragma mark Private Methods

- (void)safeApplyOperationsToFile:(DBFile *)file {
  void(^block)() = ^() {
    NSError *error;
    NSString *originalContents = [file readString:&error];
    NSAssert(!error, nil);
    NSString *newContents = [_operationAggregator string:originalContents
                            withOperationsAppliedForPath:file.info.path];
    [file writeString:newContents error:&error];
    NSAssert(!error, nil);
  };
  if ([NSOperationQueue currentQueue] == _operationQueue) {
    block();
  } else {
    [_operationQueue addOperationWithBlock:block];
  }
}

- (BOOL)shouldUpdateFile:(DBFile *)file {
  NSAssert([NSOperationQueue currentQueue] == _operationQueue, nil);
  return !file.newerStatus
      && file.status.cached;
}

@end
