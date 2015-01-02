//
//  PTAFileContentStore.h
//  Point
//
//  Created by Mikey Lintz on 1/1/15.
//  Copyright (c) 2015 Mikey Lintz. All rights reserved.
//

@interface PTAFileContentStore : NSObject

- (instancetype)initWithQueue:(NSOperationQueue *)queue;
- (instancetype)init PTA_INIT_UNAVAILABLE;

- (void)savePendingOperationsToDefaults:(NSUserDefaults *)userDefaults;
- (void)loadPendingOperationsFromDefaults:(NSUserDefaults *)userDefaults;

- (void)addFile:(DBFile *)file;
- (void)removeFile:(DBFile *)file;

- (void)applyOperation:(id<PTAFileOperation>)operation forFileAtPath:(DBPath *)path;

// Callbacks are on main queue
- (void)readContentsOfFile:(DBPath *)path
                   success:(void (^)(DBPath *path, NSString *contents))success
                   failure:(void (^)(NSError *error))failure;

@end