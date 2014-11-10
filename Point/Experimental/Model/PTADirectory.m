//
//  PTADirectory.m
//  Point
//
//  Created by Mikey Lintz on 11/9/14.
//  Copyright (c) 2014 Mikey Lintz. All rights reserved.
//

#import "PTADirectory.h"

@implementation PTADirectory

- (instancetype)init {
  return [self initWithFileInfos:nil didCompleteFirstSync:NO];
}

- (instancetype)initWithFileInfos:(NSArray *)fileInfos
             didCompleteFirstSync:(BOOL)didCompleteFirstSync {
  self = [super init];
  if (self) {
    _fileInfos = [fileInfos copy];
    _didCompleteFirstSync = didCompleteFirstSync;
  }
  return self;
}

@end
