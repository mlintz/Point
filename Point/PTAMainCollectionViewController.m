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

@interface PTAMainCollectionViewController ()<PTADocumentCollectionDelegate>
@end

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

  _collectionVC = [[PTADocumentCollectionViewController alloc] initWithFilesystemManager:_manager];
  _collectionVC.delegate = self;
  [self addChildViewController:_collectionVC];
  [self.view addSubview:_collectionVC.view];
  [_collectionVC didMoveToParentViewController:self];
}

- (void)viewWillLayoutSubviews {
  [super viewWillLayoutSubviews];
  _collectionVC.view.frame = self.view.bounds;
}

- (void)documentCollectionController:(PTADocumentCollectionViewController *)controller didSelectPath:(DBPath *)path {
  NSParameterAssert(path);
  PTADocumentViewController *vc = [[PTADocumentViewController alloc] initWithManager:_manager
                                                                                path:path];
  [self.navigationController pushViewController:vc animated:YES];
}

@end
