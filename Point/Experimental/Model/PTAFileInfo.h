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

- (instancetype)initWithPath:(DBPath *)path modifiedTime:(NSDate *)modifiedTime;

@end
