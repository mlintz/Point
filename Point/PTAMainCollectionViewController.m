//
//  PTAMainCollectionViewController.m
//  Point
//
//  Created by Mikey Lintz on 11/15/14.
//  Copyright (c) 2014 Mikey Lintz. All rights reserved.
//

#import "PTAMainCollectionViewController.h"

#import "PTADocumentCollectionViewController.h"
#import "PTADocumentViewController.h"
#import "PTAComposeBarButtonItem.h"

@implementation PTAMainCollectionViewController {
  PTAFilesystemManager *_manager;
  PTADocumentCollectionViewController *_collectionVC;
}

- (instancetype)init {
  [self doesNotRecognizeSelector:_cmd];
  return nil;
}

- (instancetype)initWithFilesystemManager:(PTAFilesystemManager *)filesystemManager {
  NSParameterAssert(filesystemManager);
  self = [super init];
  if (self) {
    _manager = filesystemManager;
    
    self.navigationItem.title = @"All Documents";
    self.navigationItem.rightBarButtonItem =
        [[PTAComposeBarButtonItem alloc] initWithController:self filesystemManager:_manager];
  }
  return self;
}

- (void)loadView {
  self.view = [[UIView alloc] init];

  PTAFilesystemManager *manager = _manager;
  __weak UIViewController *weakSelf = self;
  PTADocumentCollectionSelection callback = ^(PTADocumentCollectionViewController *collectionController,
                                              DBPath *path) {
    NSParameterAssert(path);
    PTADocumentViewController *vc = [[PTADocumentViewController alloc] initWithManager:manager
                                                                                  path:path];
    [weakSelf.navigationController pushViewController:vc animated:YES];
  };

  _collectionVC = [[PTADocumentCollectionViewController alloc] initWithFilesystemManager:_manager
                                                                                callback:callback];
  [self addChildViewController:_collectionVC];
  [self.view addSubview:_collectionVC.view];
  [_collectionVC didMoveToParentViewController:self];
}

- (void)viewWillLayoutSubviews {
  [super viewWillLayoutSubviews];
  _collectionVC.view.frame = self.view.bounds;
}

@end
