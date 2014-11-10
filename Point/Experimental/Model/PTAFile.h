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
@property(nonatomic, readonly) NSString *content;

- (instancetype)initWithInfo:(PTAFileInfo *)info content:(NSString *)content;

@end
