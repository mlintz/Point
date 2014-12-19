//
//  PTAFilesystemManager.m
//  Point
//
//  Created by Mikey Lintz on 11/9/14.
//  Copyright (c) 2014 Mikey Lintz. All rights reserved.
//

#import "PTAFilesystemManager.h"
#import "PTAFileOperation.h"

typedef void (^PTAFileChangedCallback)(PTAFilesystemManager *filesystemManager, DBFile *file);


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
  DBPath *_inboxFilePath;

  PTAFileChangedCallback _fileChangedCallback;

  NSMutableDictionary *_fileObservers;  // DBPath -> NSHashTable<PTAFileObserver>
  NSHashTable *_directoryObservers;  // PTADirectoryObserver

  NSMutableDictionary *_openFileMap;  // DBPath -> DBFile
  NSMutableSet *_pathsNeedingDispatch;
  BOOL _filesystemNeedsDispatch;
}

- (instancetype)init {
  [self doesNotRecognizeSelector:_cmd];
  return nil;
}

- (instancetype)initWithAccountManager:(DBAccountManager *)accountManager
                              rootPath:(DBPath *)rootPath
                         inboxFilePath:(DBPath *)inboxFilePath {
  NSParameterAssert(accountManager);
  NSParameterAssert(rootPath);
  NSParameterAssert(inboxFilePath);
  self = [super init];
  if (self) {
    _rootPath = rootPath;
    _filesystem = accountManager.linkedAccount
        ? [[DBFilesystem alloc] initWithAccount:accountManager.linkedAccount] : nil;
    _openFileMap = [NSMutableDictionary dictionary];

    __weak id weakSelf = self;
    __weak id weakAccountManager = accountManager;
    
    _fileChangedCallback = [^(PTAFilesystemManager *filesystemManager, DBFile *file) {
      [filesystemManager->_pathsNeedingDispatch addObject:file.info.path];
      dispatch_async(dispatch_get_main_queue(), ^{
        if ([filesystemManager->_pathsNeedingDispatch containsObject:file.info.path]) {
          [filesystemManager->_pathsNeedingDispatch removeObject:file.info.path];
          [filesystemManager publishFileChanged:file];
        }
      });
    } copy];
    
    void(^filesystemChangeCallback)() = ^ {
      PTAFilesystemManager *strongSelf = weakSelf;
      if (!strongSelf) {
        return;
      }
      strongSelf->_filesystemNeedsDispatch = YES;
      [strongSelf.class openNewFilesInFilesystem:strongSelf->_filesystem
                                        rootPath:strongSelf->_rootPath
                                   updateFileMap:strongSelf->_openFileMap
                                     addObserver:strongSelf
                                           block:strongSelf->_fileChangedCallback];
      dispatch_async(dispatch_get_main_queue(), ^{
        if (!strongSelf->_filesystemNeedsDispatch) {
          return;
        }
        strongSelf->_filesystemNeedsDispatch = NO;
        [strongSelf publishDirectoryChanged];
      });
    };

    [accountManager addObserver:self block:^(DBAccount *account) {
      PTAFilesystemManager *strongSelf = weakSelf;
      DBAccountManager *strongAccountManager = weakAccountManager;
      if (!strongSelf) {
        return;
      }
      [strongSelf->_filesystem removeObserver:strongSelf];
      strongSelf->_filesystem = strongAccountManager.linkedAccount
          ? [[DBFilesystem alloc] initWithAccount:strongAccountManager.linkedAccount] : nil;
      [strongSelf->_filesystem addObserver:self block:filesystemChangeCallback];
      [strongSelf->_filesystem addObserver:self
                        forPathAndChildren:strongSelf->_rootPath
                                     block:filesystemChangeCallback];
      [strongSelf.class openNewFilesInFilesystem:strongSelf->_filesystem
                                        rootPath:strongSelf->_rootPath
                                   updateFileMap:strongSelf->_openFileMap
                                     addObserver:strongSelf
                                           block:strongSelf->_fileChangedCallback];
      [strongSelf publishDirectoryChanged];
    }];
    _inboxFilePath = inboxFilePath;
    _fileObservers = [NSMutableDictionary dictionary];
    _directoryObservers = [NSHashTable weakObjectsHashTable];
    _pathsNeedingDispatch = [NSMutableSet set];
    
    [_filesystem addObserver:self block:filesystemChangeCallback];
    [_filesystem addObserver:self forPathAndChildren:_rootPath block:filesystemChangeCallback];
    [self.class openNewFilesInFilesystem:_filesystem
                                rootPath:_rootPath
                           updateFileMap:_openFileMap
                             addObserver:self
                                   block:_fileChangedCallback];
  }
  return self;
}

- (PTADirectory *)directory {
  return [self.class createDirectoryWithFileMap:_openFileMap
                             completedFirstSync:_filesystem.completedFirstSync];
}

- (void)addDirectoryObserver:(id<PTADirectoryObserver>)observer {
  NSAssert(observer, @"observer must be non-nil");
  [_directoryObservers addObject:observer];
}

- (void)removeDirectoryObserver:(id<PTADirectoryObserver>)observer {
  NSParameterAssert(observer);
  [_directoryObservers removeObject:observer];
}

- (void)addFileObserver:(id<PTAFileObserver>)observer forPath:(DBPath *)path {
  NSParameterAssert(observer);
  NSParameterAssert(path);
  NSHashTable *observers = _fileObservers[path];
  if (!observers) {
    observers = [NSHashTable weakObjectsHashTable];
    _fileObservers[path] = observers;
  }
  [observers addObject:observer];
}

- (void)removeFileObserver:(id<PTAFileObserver>)observer forPath:(DBPath *)path {
  NSParameterAssert(observer);
  NSParameterAssert(path);
  NSHashTable *observers = _fileObservers[path];
  [observers removeObject:observer];
  if (!observers.count) {
    [_fileObservers removeObjectForKey:path];
  }
}

- (void)removeFileObserver:(id<PTAFileObserver>)observer {
  NSAssert(observer, @"observer must be non-nil");
  NSArray *paths = [_fileObservers allKeys];
  for (DBPath *path in paths) {
    [self removeFileObserver:observer forPath:path];
  }
}

- (PTAFile *)fileForPath:(DBPath *)path {
  NSParameterAssert(path);
  NSAssert(_filesystem, @"Can't open path %@ with nil filesystem", path);
  DBFile *file = _openFileMap[path];
  if (!file) {
    DBError *error;
    file = [_filesystem createFile:path error:&error];
    NSAssert(!error, @"Error creating file, %@", file);
  }
  return [self.class createFile:file];
}

- (PTAFile *)createFileWithName:(NSString *)name {
  NSParameterAssert(name);
  NSParameterAssert(name.length);
  NSAssert(_filesystem, @"Can't create file %@ with nil filesystem", name);
  DBError *error;
  DBPath *path = [_rootPath childPath:name];
  DBFile *file = [_filesystem createFile:path error:&error];
  NSAssert(!error, @"Error creating file: %@", error.localizedDescription);
  [file close];  // Files should only be opened in |openNewFilesInFilesystem:...| below
  [self.class openNewFilesInFilesystem:_filesystem
                              rootPath:_rootPath
                         updateFileMap:_openFileMap
                           addObserver:self
                                 block:_fileChangedCallback];
  NSAssert(!error && file, @"Error creating file: %@", error.localizedDescription);
  return [self.class createFile:_openFileMap[path]];
}

- (BOOL)containsFileWithName:(NSString *)name {
  DBPath *path = [_rootPath childPath:name];
  return _openFileMap[path] != nil;
}

- (PTAFile *)writeString:(NSString *)string toFileAtPath:(DBPath *)path {
  DBFile *file = [self performFileOperation:^BOOL(DBFile *file, DBError *__autoreleasing *error) {
    NSAssert(!file.newerStatus, @"Attempting to write string to file when newer version is available.");
    return [file writeString:string error:error];
  } forPath:path];
  return [self.class createFile:file];
}

- (PTAFile *)appendString:(NSString *)string toFileAtPath:(DBPath *)path {
  DBFile *file = [self performFileOperation:^BOOL(DBFile *file, DBError *__autoreleasing *error) {
    NSAssert(!file.newerStatus, @"Attempting to append string to file when newer version is available.");
    return [file appendString:string error:error];
  } forPath:path];
  return [self.class createFile:file];
}

- (void)updateFileForPath:(DBPath *)path {
  [self performFileOperation:^BOOL(DBFile *file, DBError *__autoreleasing *error) {
    return [file update:error];
  } forPath:path];
}

- (void)appendTextToInboxFile:(NSString *)text {
  [self appendString:text toFileAtPath:_inboxFilePath];
}

- (void)applyOperationToInboxFile:(id<PTAFileOperation>)operation {
  NSParameterAssert(operation);
  PTAFile *inboxFile = [self fileForPath:_inboxFilePath];
  NSString *fileContent = inboxFile.content;
  NSAssert(fileContent.length > 0, @"Failsafe against reading empty contents from improperly opened file.");
  NSString *newContent = [operation contentByApplyingOperationToContent:fileContent];
  [self writeString:newContent toFileAtPath:inboxFile.info.path];
}

#pragma mark - Private

+ (void)openNewFilesInFilesystem:(DBFilesystem *)filesystem
                        rootPath:(DBPath *)rootPath
                   updateFileMap:(NSMutableDictionary *)fileMap  // DBPath -> DBFile
                     addObserver:(PTAFilesystemManager *)observer
                           block:(void (^)(PTAFilesystemManager *filesystemManager, DBFile *file))observerBlock {
  NSArray *fileInfos = [self fetchFileInfosFromFilesystem:filesystem rootPath:rootPath];

  // All sets are DBPath
  NSSet *oldPaths = [NSSet setWithArray:fileMap.allKeys];
  NSSet *currentPaths = [NSSet setWithArray:[fileInfos pta_arrayWithMap:^DBPath *(PTAFileInfo *fileInfo) {
    return fileInfo.path;
  }]];

  NSMutableSet *addedPaths = [currentPaths mutableCopy];
  [addedPaths minusSet:oldPaths];
  
  NSMutableSet *removedPaths = [oldPaths mutableCopy];
  [removedPaths minusSet:currentPaths];

  DBError *error;
  for (DBPath *path in addedPaths) {
    DBFile *file = [filesystem openFile:path error:&error];
    NSAssert(!error, @"%@", error.localizedDescription);
    fileMap[path] = file;
    __weak id weakFile = file;
    __weak id weakManager = observer;
    [file addObserver:observer block:^{
      PTAFilesystemManager *strongSelf = weakManager;
      DBFile *strongFile = weakFile;
      if (strongSelf && strongFile) {
        observerBlock(strongSelf, strongFile);
      }
    }];
  }

  for (DBPath *path in removedPaths) {
    DBFile *file = fileMap[path];
    [file close];
    [fileMap removeObjectForKey:path];
    [file removeObserver:observer];
  }
}

- (DBFile *)performFileOperation:(BOOL (^)(DBFile *file, DBError **error))operation
                         forPath:(DBPath *)path {
  NSParameterAssert(path);
  DBFile *file = _openFileMap[path];
  NSAssert(file, @"No open file at path %@. Paths: %@", path, _openFileMap.allKeys);
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
  return file;
}

+ (PTADirectory *)createDirectoryWithFileMap:(NSDictionary *)fileMap  // DBPath -> DBFile
                          completedFirstSync:(BOOL)completedFirstSync {
  if (completedFirstSync) {
    NSArray *files = fileMap.allValues;
    NSArray *fileInfos = [files pta_arrayWithMap:^PTAFileInfo *(DBFile *file) {
      return [[PTAFileInfo alloc] initWithPath:file.info.path modifiedTime:file.info.modifiedTime];
    }];
    return [[PTADirectory alloc] initWithFileInfos:fileInfos didCompleteFirstSync:YES];
  }
  return [[PTADirectory alloc] initWithFileInfos:@[] didCompleteFirstSync:NO];
}

+ (NSArray *)fetchFileInfosFromFilesystem:(DBFilesystem *)filesystem
                                 rootPath:(DBPath *)rootPath {
  if (filesystem.completedFirstSync) {
    NSError *error;
    NSMutableArray *infos = [NSMutableArray array];
    for (DBFileInfo *fileInfo in [filesystem listFolder:rootPath error:&error]) {
      NSAssert(!error, @"error: %@", error.localizedDescription);
      PTAFileInfo *info = [[PTAFileInfo alloc] initWithPath:fileInfo.path
                                               modifiedTime:fileInfo.modifiedTime];
      [infos addObject:info];
    }
    return infos;
  }
  return @[];
}

+ (PTAFile *)createFile:(DBFile *)file {
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
  PTADirectory *directory = [self.class createDirectoryWithFileMap:_openFileMap
                                                completedFirstSync:_filesystem.completedFirstSync];
  for (id<PTADirectoryObserver> observer in _directoryObservers) {
    [observer directoryDidChange:directory];
  }
}

- (void)publishFileChanged:(DBFile *)file {
  NSHashTable *fileObservers = _fileObservers[file.info.path];
  if (!fileObservers.count) {
    return;
  }
  PTAFile *ptafile = [self.class createFile:file];
  for (id<PTAFileObserver> observer in fileObservers.objectEnumerator) {
    [observer fileDidChange:ptafile];
  }
}

@end
