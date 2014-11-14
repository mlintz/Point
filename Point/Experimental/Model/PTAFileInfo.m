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
  PTAFileInfo *other = object;
  return [self.path.stringValue isEqual:other.path.stringValue];
}

- (NSUInteger)hash {
  return [self.path.stringValue hash];
}

@end
