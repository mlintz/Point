//
//  PTAFileInfo.m
//  Point
//
//  Created by Mikey Lintz on 11/9/14.
//  Copyright (c) 2014 Mikey Lintz. All rights reserved.
//

#import "PTAFileInfo.h"

@implementation PTAFileInfo

- (instancetype)init {
  [self doesNotRecognizeSelector:_cmd];
  return nil;
}

- (instancetype)initWithPath:(DBPath *)path modifiedTime:(NSDate *)modifiedTime {
  NSAssert(path && modifiedTime, @"path (%@) and date (%@) must be non-nil", path, modifiedTime);
  self = [super init];
  if (self) {
    _path = [path copy];;
    _modifiedTime = [modifiedTime copy];
  }
  return self;
}

- (id)copyWithZone:(NSZone *)zone {
  return self;
}

- (BOOL)isEqual:(id)object {
  if (![object isKindOfClass:[PTAFileInfo class]]) {
    return NO;
  }
  return [self isEqualToFileInfo:(PTAFileInfo *)object];
}

- (BOOL)isEqualToFileInfo:(PTAFileInfo *)fileInfo {
  if (self == fileInfo) {
    return YES;
  }
  if (![self.path isEqual:fileInfo.path] && self.path != fileInfo.path) {
    return NO;
  }
  if (![self.modifiedTime isEqualToDate:fileInfo.modifiedTime] && self.modifiedTime != fileInfo.modifiedTime) {
    return NO;
  }
  return YES;
}

- (NSUInteger)hash {
  return [self.path.stringValue hash];
}

@end
