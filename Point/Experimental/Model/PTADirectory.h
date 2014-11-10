//
//  PTADirectory.h
//  Point
//
//  Created by Mikey Lintz on 11/9/14.
//  Copyright (c) 2014 Mikey Lintz. All rights reserved.
//

// Immutable
@interface PTADirectory : NSObject<NSCopying>

@property(nonatomic, readonly) BOOL didCompleteFirstSync;
@property(nonatomic, readonly) NSArray *fileInfos;  // PTAFileInfo

- (instancetype)initWithFileInfos:(NSArray *)fileInfos
             didCompleteFirstSync:(BOOL)didCompleteFirstSync;

@end
