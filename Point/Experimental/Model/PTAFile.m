//
//  PTAFile.m
//  Point
//
//  Created by Mikey Lintz on 11/9/14.
//  Copyright (c) 2014 Mikey Lintz. All rights reserved.
//

#import "PTAFile.h"

#import "PTAFileInfo.h"

@implementation PTAFile

// XXX(mlintz): implement isequals and hash

- (instancetype)init {
  return [self initWithInfo:nil content:nil];
}

- (instancetype)initWithInfo:(PTAFileInfo *)info content:(NSString *)content {
  self = [super init];
  if (self) {
    _info = [info copy];
    _content = [content copy];
  }
  return self;
}

- (id)copyWithZone:(NSZone *)zone {
  return self;
}

- (BOOL)isEqual:(id)object {
  if (![object isKindOfClass:[PTAFile class]]) {
    return NO;
  }
  PTAFile *other = object;
  return [self.info isEqual:other.info];
}

- (NSUInteger)hash {
  return [self.info hash];
}

@end
