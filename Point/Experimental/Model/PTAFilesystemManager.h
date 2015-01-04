//
//  PTAFilesystemManager.h
//  Point
//
//  Created by Mikey Lintz on 11/9/14.
//  Copyright (c) 2014 Mikey Lintz. All rights reserved.
//

@class PTADirectory;
@class PTAFile;
@class PTAFilesystemManager;
@protocol PTAFileOperation;

@protocol PTAFileObserver <NSObject>

- (void)fileDidChange:(PTAFile *)file;

@end

@protocol PTADirectoryObserver <NSObject>

- (void)directoryDidChange:(PTADirectory *)directory;

@end

@protocol PTAFilesystemManagerDelegate <NSObject>

// Return NO from either method to suppress notification.
- (BOOL)manager:(PTAFilesystemManager *)manager willPublishFileChange:(PTAFile *)file;
- (void)manager:(PTAFilesystemManager *)manager applyInitialTransformToFile:(PTAFile *)file;

@end

//  Task(mlintz): Maybe separate into a collection of protocols grouping functions by task.
//    e.g. Writers, Openers, Directors
@interface PTAFilesystemManager : NSObject

@property(nonatomic, readonly) PTADirectory *directory;
@property(nonatomic, weak) id<PTAFilesystemManagerDelegate> delegate;

- (instancetype)initWithAccountManager:(DBAccountManager *)accountManager
                              rootPath:(DBPath *)rootPath
                         inboxFilePath:(DBPath *)inboxFilePath
                        operationQueue:(NSOperationQueue *)queue;

// add/remove parameters must be non-nil
- (void)addDirectoryObserver:(id<PTADirectoryObserver>)observer;
- (void)removeDirectoryObserver:(id<PTADirectoryObserver>)observer;

// add/remove parameters must be non-nil
- (void)addFileObserver:(id<PTAFileObserver>)observer forPath:(DBPath *)path;
- (void)removeFileObserver:(id<PTAFileObserver>)observer forPath:(DBPath *)path;
- (void)removeFileObserver:(id<PTAFileObserver>)observer;

// Creates file if it doesn't exist
- (RXPromise *)fileForPath:(DBPath *)path;  // PTAFile

// Returns nil if it doesn't exist
- (NSString *)filenameWithEmojiStatusForPath:(DBPath *)path;

- (RXPromise *)createFileWithName:(NSString *)name;  // PTAFile
- (BOOL)containsFileWithName:(NSString *)name;
- (void)updateFileForPath:(DBPath *)path;

// File must be open and without an available newer version to write
- (RXPromise *)writeString:(NSString *)string toFileAtPath:(DBPath *)path;  // PTAFile
- (RXPromise *)appendString:(NSString *)string toFileAtPath:(DBPath *)path;  // PTAFile
- (RXPromise *)appendStringToInboxFile:(NSString *)string;  // PTAFile

@end
