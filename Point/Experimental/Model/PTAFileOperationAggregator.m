//
//  PTAFileOperationAggregator.m
//  Point
//
//  Created by Mikey Lintz on 12/18/14.
//  Copyright (c) 2014 Mikey Lintz. All rights reserved.
//

#import "PTAFileOperationAggregator.h"

#import "PTAFileOperation.h"

#define AssertOnExpectedQueue NSAssert(!self.queue || [NSOperationQueue currentQueue] == self.queue, @"%@ called from foreign queue.", NSStringFromSelector(_cmd))


NSString * const kOperationMapKey = @"PTAFileOperationAggregator.operationMap";

@implementation PTAFileOperationAggregator {
  NSMutableDictionary *_operationMap;  // DBPath -> NSMutableArray<id<PTAFileOperation>>
}

+ (instancetype)aggregator {
  return [[self alloc] initWithOperationMap:@{}];
}

- (instancetype)init {
  [self doesNotRecognizeSelector:_cmd];
  return nil;
}

- (instancetype)initWithOperationMap:(NSDictionary *)operationMap {
  NSParameterAssert(operationMap);
  self = [super init];
  if (self) {
    _operationMap = [operationMap mutableCopy];
  }
  return self;
}

- (void)addOperation:(NSObject<PTAFileOperation> *)operation forFileAtPath:(DBPath *)path {
  NSParameterAssert(operation);
  NSParameterAssert(path);
  AssertOnExpectedQueue;

  NSString *key = [self.class keyFromPath:path];
  NSMutableArray *operationQueue = _operationMap[key];
  if (!operationQueue) {
    operationQueue = [NSMutableArray array];
    _operationMap[key] = operationQueue;
  }
  [operationQueue addObject:[operation copy]];
}

- (BOOL)hasOperationForFileAtPath:(DBPath *)path {
  NSParameterAssert(path);
  AssertOnExpectedQueue;
  
  NSString *key = [self.class keyFromPath:path];
  NSMutableArray *operationQueue = _operationMap[key];
  return operationQueue.count > 0;
}

- (void)removeAllOperationForFileAtPath:(DBPath *)path {
  AssertOnExpectedQueue;
  NSString *key = [self.class keyFromPath:path];
  [_operationMap removeObjectForKey:key];
}

- (NSString *)string:(NSString *)string withOperationsAppliedForPath:(DBPath *)path {
  AssertOnExpectedQueue;
  NSString *key = [self.class keyFromPath:path];
  NSArray *operationQueue = _operationMap[key];
  if (!operationQueue) {
    return string;
  }
  NSString *transformedString = string;
  for (id<PTAFileOperation> operation in operationQueue) {
    transformedString = [operation contentByApplyingOperationToContent:transformedString];
  }
  return transformedString;
}

#pragma mark - NSCoding

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
  NSDictionary *operationsMap = [aDecoder decodeObjectOfClass:[NSDictionary class]
                                                       forKey:kOperationMapKey]
      ?: @{};
  return [self initWithOperationMap:operationsMap];
}

- (void)encodeWithCoder:(NSCoder *)aCoder {
  [aCoder encodeObject:_operationMap forKey:kOperationMapKey];
}

#pragma mark - Private

+ (NSString *)keyFromPath:(DBPath *)path {
  return [[path stringValue] lowercaseString];
}

@end
