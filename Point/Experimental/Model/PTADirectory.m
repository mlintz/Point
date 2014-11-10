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
  [self doesNotRecognizeSelector:_cmd];
  return nil;
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

- (id)copyWithZone:(NSZone *)zone {
  return self;
}

@end
