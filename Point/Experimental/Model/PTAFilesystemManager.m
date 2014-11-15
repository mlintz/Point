//
//  PTAFilesystemManager.m
//  Point
//
//  Created by Mikey Lintz on 11/9/14.
//  Copyright (c) 2014 Mikey Lintz. All rights reserved.
//

#import "PTAFilesystemManager.h"

#import "PTADirectory.h"
#import "PTAFile.h"
#import "PTAFileInfo.h"

@interface NSArray (DocumentCollection)
- (NSArray *)pta_filteredArrayWithPathExtension:(NSString *)pathExtension;
@end

@implementation NSArray (DocumentCollection)

- (NSArray *)pta_filteredArrayWithPathExtension:(NSString *)pathExtension {
  return [self filteredArrayUsingPredicate:[NSPredicate predicateWithBlock:^BOOL(DBFileInfo *info, NSDictionary *_) {
    return [info.path.name.pathExtension isEqualToString:pathExtension];
  }]];
}

@end

@implementation PTAFilesystemManager {
  DBFilesystem *_filesystem;
  DBPath *_rootPath;

  NSMutableDictionary *_fileObservers;  // DBPath -> NSHashTable<PTAFileObserver>
  NSHashTable *_directoryObservers;  // PTADirectoryObserver
  NSMutableDictionary *_filesMap;  // DBPath -> DBFile

  NSMutableSet *_pathsNeedingDispatch;
  BOOL _filesystemNeedsDispatch;
}

- (instancetype)init {
  [self doesNotRecognizeSelector:_cmd];
  return nil;
}

- (instancetype)initWithFilesystem:(DBFilesystem *)fileSystem rootPath:(DBPath *)rootPath {
  NSAssert(fileSystem && rootPath, @"fileSystem must be non-nil.");
  self = [super init];
  if (self) {
    _filesystem = fileSystem;
    _rootPath = rootPath;
    _fileObservers = [NSMutableDictionary dictionary];
    _directoryObservers = [NSHashTable weakObjectsHashTable];
    _pathsNeedingDispatch = [NSMutableSet set];
    _filesMap = [NSMutableDictionary dictionary];
    
    __weak id weakSelf = self;
    void(^filesystemChangeCallback)() = ^void() {
      PTAFilesystemManager *strongSelf = weakSelf;
      if (!strongSelf) {
        return;
      }
      strongSelf->_filesystemNeedsDispatch = YES;
      dispatch_async(dispatch_get_main_queue(), ^{
        if (!strongSelf->_filesystemNeedsDispatch) {
          return;
        }
        strongSelf->_filesystemNeedsDispatch = NO;
        [strongSelf publishDirectoryChanged];
      });
    };
    
    [_filesystem addObserver:self block:filesystemChangeCallback];
    [_filesystem addObserver:self forPathAndChildren:_rootPath block:filesystemChangeCallback];
  }
  return self;
}

- (PTADirectory *)directory {
  return [self createDirectory];
}

- (void)addDirectoryObserver:(id<PTADirectoryObserver>)observer {
  NSAssert(observer, @"observer must be non-nil");
  [_directoryObservers addObject:observer];
}

- (void)removeDirectoryObserver:(id<PTADirectoryObserver>)observer {
  NSAssert(observer, @"observer must be non-nil");
  [_directoryObservers removeObject:observer];
}

- (void)addFileObserver:(id<PTAFileObserver>)observer forPath:(DBPath *)path {
  NSAssert(observer && path, @"observer (%@) and path (%@) must be non-nil", observer, path);
  NSHashTable *observers = _fileObservers[path];
  if (!observers) {
    observers = [NSHashTable weakObjectsHashTable];
    _fileObservers[path] = observers;
  }
  [observers addObject:observer];
}

- (void)removeFileObserver:(id<PTAFileObserver>)observer forPath:(DBPath *)path {
  NSAssert(observer && path, @"observer (%@) and path (%@) must be non-nil", observer, path);
  NSHashTable *observers = _fileObservers[path];
  [observers removeObject:observer];
  if (!observers.count) {
    _fileObservers[path] = nil;
  }
}

- (void)removeFileObserver:(id<PTAFileObserver>)observer {
  NSAssert(observer, @"observer must be non-nil");
  NSArray *paths = [_fileObservers allKeys];
  for (DBPath *path in paths) {
    [self removeFileObserver:observer forPath:path];
  }
}

- (PTAFile *)openFileForPath:(DBPath *)path {
  NSAssert(path, @"path must be non-nil");
  if (_filesMap[path] != nil) {
    return [self createFile:_filesMap[path]];
  }
  DBError *error;
  DBFile *file = [_filesystem openFile:path error:&error];
  if (error || !file) {
    NSAssert([error code] == DBErrorParamsNotFound, @"Received non DBErrorParamsNotFound error: %@", error.localizedDescription);
    return nil;
  }
  _filesMap[path] = file;
  __weak id weakSelf = self;
  __weak id weakFile = file;
  [file addObserver:self block:^{
    PTAFilesystemManager *strongSelf = weakSelf;
    DBFile *strongFile = weakFile;
    if (!strongSelf || !strongFile) {
      return;
    }
    [strongSelf->_pathsNeedingDispatch addObject:path];
    dispatch_async(dispatch_get_main_queue(), ^{
      if ([strongSelf->_pathsNeedingDispatch containsObject:path]) {
        [strongSelf->_pathsNeedingDispatch removeObject:path];
        [self publishFileChanged:strongFile];
      }
    });
  }];
  return [self createFile:file];
}

- (void)closeFileForPath:(DBPath *)path {
  DBFile *file = _filesMap[path];
  [file close];
  [_filesMap removeObjectForKey:path];
}

- (void)writeString:(NSString *)string toFileAtPath:(DBPath *)path {
  [self performFileOperation:^BOOL(DBFile *file, DBError *__autoreleasing *error) {
    NSAssert(!file.newerStatus, @"File must be fully synced.");
    return [file writeString:string error:error];
  } forPath:path];
}

- (void)appendString:(NSString *)string toFileAtPath:(DBPath *)path {
  [self performFileOperation:^BOOL(DBFile *file, DBError *__autoreleasing *error) {
    NSAssert(!file.newerStatus, @"File must be fully synced.");
    return [file appendString:string error:error];
  } forPath:path];
}

- (void)updateFileForPath:(DBPath *)path {
  [self performFileOperation:^BOOL(DBFile *file, DBError *__autoreleasing *error) {
    return [file update:error];
  } forPath:path];
}

#pragma mark - Private

- (void)performFileOperation:(BOOL (^)(DBFile *file, DBError **error))operation
                     forPath:(DBPath *)path {
  NSAssert(path, @"path must be non-nil");
  DBFile *file = _filesMap[path];
  NSAssert(file, @"No open file at path %@. Paths: %@", path, _filesMap.allKeys);
  NSAssert(file.open, @"File must be open to write to it.");
  DBError *error;
  BOOL success = operation(file, &error);
  NSAssert(success && !error, @"Error writing file: %@", error.localizedDescription);
  
  [_pathsNeedingDispatch addObject:path];
  dispatch_async(dispatch_get_main_queue(), ^{
    if ([self->_pathsNeedingDispatch containsObject:path]) {
      [self->_pathsNeedingDispatch removeObject:path];
      [self publishFileChanged:file];
    }
  });
}

- (PTADirectory *)createDirectory {
  PTADirectory *directory;
  if (_filesystem.completedFirstSync) {
    NSError *error;
    NSMutableArray *infos = [NSMutableArray array];
    for (DBFileInfo *fileInfo in [_filesystem listFolder:_rootPath error:&error]) {
      NSAssert(!error, @"error: %@", error.localizedDescription);
      PTAFileInfo *info = [[PTAFileInfo alloc] initWithPath:fileInfo.path
                                               modifiedTime:fileInfo.modifiedTime];
      [infos addObject:info];
    }
    directory = [[PTADirectory alloc] initWithFileInfos:infos
                                   didCompleteFirstSync:YES];
  } else {
    directory = [[PTADirectory alloc] initWithFileInfos:nil
                                   didCompleteFirstSync:NO];
  }
  return directory;
}

- (PTAFile *)createFile:(DBFile *)file {
  NSString *content;
  NSError *error;
  if (file.status.cached) {
    content = [file readString:&error];
    NSAssert(!error, @"Error reading file: %@", error.localizedDescription);
  }
  return [[PTAFile alloc] initWithFile:file content:content];
}

- (void)publishDirectoryChanged {
  if (!_directoryObservers.count) {
    return;
  }
  PTADirectory *directory = [self createDirectory];
  for (id<PTADirectoryObserver> observer in _directoryObservers) {
    [observer directoryDidChange:directory];
  }
}

- (void)publishFileChanged:(DBFile *)file {
  NSHashTable *fileObservers = _fileObservers[file.info.path];
  if (!fileObservers.count) {
    return;
  }
  PTAFile *ptafile = [self createFile:file];
  for (id<PTAFileObserver> observer in fileObservers.objectEnumerator) {
    [observer fileDidChange:ptafile];
  }
}

@end
