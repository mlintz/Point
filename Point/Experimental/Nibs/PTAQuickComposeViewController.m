//
//  PTAQuickComposeViewController.m
//  Point
//
//  Created by Mikey Lintz on 11/14/14.
//  Copyright (c) 2014 Mikey Lintz. All rights reserved.
//

#import "PTAQuickComposeViewController.h"
#import "PTAComposeBarButtonItem.h"

@implementation PTAQuickComposeViewController {
  PTAFilesystemManager *_filesystemManager;
}

- (instancetype)init {
  [self doesNotRecognizeSelector:_cmd];
  return nil;
}

- (instancetype)initWithFilesystemManager:(PTAFilesystemManager *)filesystemManager {
  NSParameterAssert(filesystemManager);
  self = [super init];
  if (self) {
    _filesystemManager = filesystemManager;
    self.navigationItem.title = @"Foo";
  }
  return self;
}

- (void)loadView {
  self.view = [[UIView alloc] init];
  self.view.backgroundColor = [UIColor cyanColor];
}

@end
