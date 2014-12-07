//
//  PTAFile.h
//  Point
//
//  Created by Mikey Lintz on 11/9/14.
//  Copyright (c) 2014 Mikey Lintz. All rights reserved.
//

@class PTAFileInfo;

// Immutable
@interface PTAFile : NSObject<NSCopying>

@property(nonatomic, readonly) PTAFileInfo *info;
@property(nonatomic, readonly) BOOL isOpen;
@property(nonatomic, readonly) BOOL cached;
@property(nonatomic, readonly) DBFileState state;
@property(nonatomic, readonly) float progress;
@property(nonatomic, readonly) BOOL hasNewerVersion;
@property(nonatomic, readonly) NSString *content;

@property(nonatomic, readonly) NSString *nameWithEmojiStatus;

- (instancetype)initWithFile:(DBFile *)file content:(NSString *)content;

@end
