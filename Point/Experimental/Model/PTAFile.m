//
//  PTAFile.m
//  Point
//
//  Created by Mikey Lintz on 11/9/14.
//  Copyright (c) 2014 Mikey Lintz. All rights reserved.
//

#import "PTAFile.h"

#import "PTAFileInfo.h"

static NSString *PTAEmojiForFile(PTAFile *file) {
  if (!file.isOpen) {
    return @"🔒";
  }
  if (file.newerVersionStatus != kPTAFileNewerVersionStatusNone) {
    return file.newerVersionStatus == kPTAFileNewerVersionStatusDownloading ? @"⬇️💥" : @"💥";
  }
  if (!file.cached && (file.state == DBFileStateIdle)) {
    return @"📭";
  }
  if (file.state != DBFileStateIdle) {
    NSString *direction = (file.state) == DBFileStateUploading ? @"⬆️" : @"⬇️";
    NSString *progressEmoji;
    if (file.progress == 0) {
      progressEmoji = @"🌑";
    } else if (file.progress < 0.33f) {
      progressEmoji = @"🌒";
    } else if (file.progress < 0.66f) {
      progressEmoji = @"🌓";
    } else if (file.progress < 1) {
      progressEmoji = @"🌔";
    } else {
      progressEmoji = @"🌕";
    }
    return [NSString stringWithFormat:@"%@%@", direction, progressEmoji];
  }
  return @"✅";
}

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
  }
  return self;
}

- (NSString *)nameWithEmojiStatus {
  return [NSString stringWithFormat:@"%@%@", PTAEmojiForFile(self), self.info.path.name];
}

- (id)copyWithZone:(NSZone *)zone {
  return self;
}

@end
