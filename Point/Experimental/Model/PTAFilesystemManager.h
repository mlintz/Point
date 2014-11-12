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

@interface PTAFilesystemManager : NSObject

@property(nonatomic, readonly) PTADirectory *directory;

- (instancetype)initWithFilesystem:(DBFilesystem *)fileSystem rootPath:(DBPath *)rootPath;

// add/remove parameters must be non-nil
- (void)addDirectoryObserver:(id<PTADirectoryObserver>)observer;
- (void)removeDirectoryObserver:(id<PTADirectoryObserver>)observer;

// add/remove parameters must be non-nil
- (void)addFileObserver:(id<PTAFileObserver>)observer forPath:(DBPath *)path;
- (void)removeFileObserver:(id<PTAFileObserver>)observer forPath:(DBPath *)path;
- (void)removeFileObserver:(id<PTAFileObserver>)observer;

// Returns nil if no file at path.
- (PTAFile *)openFileForPath:(DBPath *)path;
// XXX(mlintz): probably can't make this a local decision
- (void)closeFileForPath:(DBPath *)path;
- (void)writeString:(NSString *)string toFileAtPath:(DBPath *)path;
- (void)appendString:(NSString *)string toFileAtPath:(DBPath *)path;
- (void)updateFileForPath:(DBPath *)path;

@end
