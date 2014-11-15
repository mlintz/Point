//
//  PTAComposeBarButtonItem.m
//  Point
//
//  Created by Mikey Lintz on 11/14/14.
//  Copyright (c) 2014 Mikey Lintz. All rights reserved.
//

#import "PTAComposeBarButtonItem.h"

@implementation PTAComposeBarButtonItem {
  __weak UIViewController *_controller;
  PTAFilesystemManager *_manager;
}

- (instancetype)initWithController:(UIViewController *)controller
                 filesystemManager:(PTAFilesystemManager *)manager {
  NSParameterAssert(controller);
  NSParameterAssert(manager);
  self = [super initWithBarButtonSystemItem:UIBarButtonSystemItemAdd target:self action:@selector(handleTap:)];
  if (self) {
    _controller = controller;
    _manager = manager;
  }
  return self;
}

- (void)handleTap:(id)sender {

}

@end
