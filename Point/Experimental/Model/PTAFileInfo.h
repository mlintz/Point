//
//  PTAFileInfo.h
//  Point
//
//  Created by Mikey Lintz on 11/9/14.
//  Copyright (c) 2014 Mikey Lintz. All rights reserved.
//

// Immutable
@interface PTAFileInfo : NSObject<NSCopying>

@property(nonatomic, readonly) DBPath *path;
@property(nonatomic, readonly) NSDate *modifiedTime;
@property(nonatomic, readonly) BOOL isOpen;
@property(nonatomic, readonly) BOOL isCached;
@property(nonatomic, readonly) DBFileState state;
@property(nonatomic, readonly) DBError *error;
@property(nonatomic, readonly) BOOL hasNewerVersion;

- (instancetype)initWithFile:(DBFile *)file;

@end
