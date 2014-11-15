//
//  PTAComposeBarButtonItem.m
//  Point
//
//  Created by Mikey Lintz on 11/14/14.
//  Copyright (c) 2014 Mikey Lintz. All rights reserved.
//

#import "PTAComposeBarButtonItem.h"
#import "PTAQuickComposeViewController.h"

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
  PTAQuickComposeViewController *vc = [[PTAQuickComposeViewController alloc] initWithFilesystemManager:_manager];
  UINavigationController *navigationController =
      [[UINavigationController alloc] initWithRootViewController:vc];
  [_controller.navigationController presentViewController:navigationController animated:YES completion:nil];
}

@end
