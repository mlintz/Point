//
//  PTAFile.m
//  Point
//
//  Created by Mikey Lintz on 11/9/14.
//  Copyright (c) 2014 Mikey Lintz. All rights reserved.
//

#import "PTAFile.h"

#import "PTAFileInfo.h"

static NSString *PTAEmojiForFile(DBError *error,
                                 BOOL isOpen,
                                 BOOL hasNewerVersion,
                                 BOOL cached,
                                 DBFileState state,
                                 float progress) {
  if (error) {
    return @"‼️";
  }
  if (!isOpen) {
    return @"🔒";
  }
  if (hasNewerVersion) {
    return @"💥";
  }
  if (!cached && (state == DBFileStateIdle)) {
    return @"📭";
  }
  if (state != DBFileStateIdle) {
    NSString *direction = state == DBFileStateUploading ? @"⬆️" : @"⬇️";
    NSString *progressEmoji;
    if (progress == 0) {
      progressEmoji = @"🌑";
    } else if (progress < 0.33f) {
      progressEmoji = @"🌒";
    } else if (progress < 0.66f) {
      progressEmoji = @"🌓";
    } else if (progress < 1) {
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
    _error = file.status.error;
    _hasNewerVersion = (file.newerStatus != nil);
    _content = [content copy];
    _progress = file.status.progress;

    NSString *emojiStatus = PTAEmojiForFile(_error, _isOpen, _hasNewerVersion, _cached, _state, _progress);
    _nameWithEmojiStatus = [NSString stringWithFormat:@"%@%@", emojiStatus, _info.path.name];
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
