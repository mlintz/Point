//
//  PTAFilesystem.m
//  Point
//
//  Created by Mikey Lintz on 7/19/14.
//  Copyright (c) 2014 Mikey Lintz. All rights reserved.
//

#import "PTAFilesystem.h"

#import <Dropbox/Dropbox.h>
#import <Bolts/Bolts.h>

static PTAFilesystem *gSharedFilesystem;

@implementation PTAFilesystem {
  DBAccountManager *_manager;
  DBFilesystem *_filesystem;
  BFTaskCompletionSource *_syncCompletionSource;
}

+ (instancetype)getSharedInstance {
  return gSharedFilesystem;
}

+ (void)setSharedInstance:(PTAFilesystem *)fileSystem {
  gSharedFilesystem = fileSystem;
}

- (id)init {
  [self doesNotRecognizeSelector:_cmd];
  return nil;
}

- (instancetype)initWithAppKey:(NSString *)key secret:(NSString *)secret {
  NSAssert([key length] && [secret length], @"Parameters must be non-empty.");
  self = [super init];
  if (self) {
    _manager = [[DBAccountManager alloc] initWithAppKey:key secret:secret];
  }
  return self;
}

- (void)linkAccountWithViewController:(UIViewController *)target {
  NSAssert(_filesystem == nil, @"Filesystem is non-nil.");
  if (!_manager.linkedAccount) {
    [_manager linkFromController:target];
  } else {
    _filesystem = [[DBFilesystem alloc] initWithAccount:_manager.linkedAccount];
    [_filesystem addObserver:self block:^{
//      code
    }];
  }
}

- (BOOL)handleOpenURL:(NSURL *)url {
  [_manager handleOpenURL:url];
  return NO;
}

- (BFTask *)fetchAllFiles {
  NSAssert(_filesystem, @"Filesystem must be non-nil.");
  return nil;
}

@end
