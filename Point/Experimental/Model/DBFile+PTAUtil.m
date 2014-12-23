//
//  DBFile+PTAUtil.m
//  Point
//
//  Created by Mikey Lintz on 12/22/14.
//  Copyright (c) 2014 Mikey Lintz. All rights reserved.
//

#import "DBFile+PTAUtil.h"

@implementation DBFile (PTAUtil)

- (NSString *)pta_nameWithEmojiStatus {
  NSString *prefix;
  if (!self.open) {
    prefix = @"🔒";
  } else if (self.newerStatus != nil) {
    prefix = self.newerStatus.state == DBFileStateDownloading ? @"⬇️💥" : @"💥";
  } else if (!self.status.cached && (self.status.state == DBFileStateIdle)) {
    prefix = @"📭";
  } else if (self.status.state != DBFileStateIdle) {
    NSString *direction = (self.status.state) == DBFileStateUploading ? @"⬆️" : @"⬇️";
    NSString *progressEmoji;
    if (self.status.progress == 0) {
      progressEmoji = @"🌑";
    } else if (self.status.progress < 0.33f) {
      progressEmoji = @"🌒";
    } else if (self.status.progress < 0.66f) {
      progressEmoji = @"🌓";
    } else if (self.status.progress < 1) {
      progressEmoji = @"🌔";
    } else {
      progressEmoji = @"🌕";
    }
    prefix = [NSString stringWithFormat:@"%@%@", direction, progressEmoji];
  } else {
    prefix = @"✅";
  }

  return [NSString stringWithFormat:@"%@%@", prefix, self.info.path.name];
}

@end
