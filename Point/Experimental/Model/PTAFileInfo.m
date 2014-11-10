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

- (instancetype)initWithFile:(DBFile *)file {
  self = [super init];
  if (self) {
    _path = [file.info.path copy];
    _modifiedTime = [file.info.modifiedTime copy];
    _isOpen = file.open;
    _isCached = file.status.cached;
    _state = file.status.state;
    _error = file.status.error;
    _hasNewerVersion = (file.newerStatus != nil);
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
