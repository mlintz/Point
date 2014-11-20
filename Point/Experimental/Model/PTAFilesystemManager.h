//
//  PTAFilesystemManager.h
//  Point
//
//  Created by Mikey Lintz on 11/9/14.
//  Copyright (c) 2014 Mikey Lintz. All rights reserved.
//

@class PTAFile;
@class PTADirectory;

@protocol PTAFileObserver <NSObject>
- (void)fileDidChange:(PTAFile *)file;
@end

@protocol PTADirectoryObserver <NSObject>
- (void)directoryDidChange:(PTADirectory *)directory;
@end

//  Task(mlintz): Maybe separate into a collection of protocols grouping functions by task.
//    e.g. Writers, Openers, Directors
@interface PTAFilesystemManager : NSObject

@property(nonatomic, readonly) PTADirectory *directory;

- (instancetype)initWithAccountManager:(DBAccountManager *)accountManager
                              rootPath:(DBPath *)rootPath
                         inboxFilePath:(DBPath *)inboxFilePath;

// add/remove parameters must be non-nil
- (void)addDirectoryObserver:(id<PTADirectoryObserver>)observer;
- (void)removeDirectoryObserver:(id<PTADirectoryObserver>)observer;

// add/remove parameters must be non-nil
- (void)addFileObserver:(id<PTAFileObserver>)observer forPath:(DBPath *)path;
- (void)removeFileObserver:(id<PTAFileObserver>)observer forPath:(DBPath *)path;
- (void)removeFileObserver:(id<PTAFileObserver>)observer;

// Creates file if it doesn't exist
- (PTAFile *)openFileForPath:(DBPath *)path;

// Asserts if file already exists. Client is responsible for releasing file.
- (PTAFile *)createFileWithName:(NSString *)name;
- (BOOL)containsFileWithName:(NSString *)name;

- (void)releaseFileForPath:(DBPath *)path;
- (void)updateFileForPath:(DBPath *)path;

// File must be open and without an available newer version to write or append
- (PTAFile *)writeString:(NSString *)string toFileAtPath:(DBPath *)path;
- (PTAFile *)appendString:(NSString *)string toFileAtPath:(DBPath *)path;

// Inbox file doesn't need to be opened to append
- (void)appendTextToInboxFile:(NSString *)string;

@end
