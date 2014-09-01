//
//  PTAFilesystem.h
//  Point
//
//  Created by Mikey Lintz on 7/19/14.
//  Copyright (c) 2014 Mikey Lintz. All rights reserved.
//

@class BFTask;

@interface PTAFilesystem : NSObject

+ (instancetype)getSharedInstance;
+ (void)setSharedInstance:(PTAFilesystem *)fileSystem;

- (instancetype)initWithAppKey:(NSString *)key
                        secret:(NSString *)secret;
- (void)linkAccountWithViewController:(UIViewController *)target;
- (BOOL)handleOpenURL:(NSURL *)url;
- (BFTask *)fetchAllFiles;  // PTAFile

@end
