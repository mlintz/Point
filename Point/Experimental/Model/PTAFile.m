//
//  PTAFile.m
//  Point
//
//  Created by Mikey Lintz on 11/9/14.
//  Copyright (c) 2014 Mikey Lintz. All rights reserved.
//

#import "PTAFile.h"

#import "DBFile+PTAUtil.h"
#import "PTAFileInfo.h"

@implementation PTAFile

- (instancetype)init {
  [self doesNotRecognizeSelector:_cmd];
  return nil;
}

- (instancetype)initWithFile:(DBFile *)file content:(NSString *)content {
  NSAssert(file, @"file must be non-nil");
  self = [super init];
  if (self) {
    _info = [[PTAFileInfo alloc] initWithPath:file.info.path modifiedTime:file.info.modifiedTime];
    _isOpen = file.open;
    _cached = file.status.cached;
    _state = file.status.state;
    if (!file.newerStatus) {
      _newerVersionStatus = kPTAFileNewerVersionStatusNone;
    } else {
      _newerVersionStatus = file.newerStatus.cached
          ? kPTAFileNewerVersionStatusCached : kPTAFileNewerVersionStatusDownloading;
    }
    _content = [content copy];
    _progress = file.status.progress;
    _nameWithEmojiStatus = [file pta_nameWithEmojiStatus];
  }
  return self;
}

- (id)copyWithZone:(NSZone *)zone {
  return self;
}

@end
