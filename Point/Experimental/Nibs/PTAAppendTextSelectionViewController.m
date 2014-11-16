//
//  PTAAppendTextSelectionViewController.m
//  Point
//
//  Created by Mikey Lintz on 11/15/14.
//  Copyright (c) 2014 Mikey Lintz. All rights reserved.
//

#import "PTAAppendTextSelectionViewController.h"

#import "PTADocumentCollectionViewController.h"
#import "UIView+Toast.h"

@interface PTAAppendTextSelectionViewController ()<PTADocumentCollectionDelegate>
@end

@implementation PTAAppendTextSelectionViewController {
  PTAFilesystemManager *_manager;
  NSString *_appendText;
  PTADocumentCollectionViewController *_collectionVC;
}

- (instancetype)init {
  [self doesNotRecognizeSelector:_cmd];
  return nil;
}

- (instancetype)initWithFilesystemManager:(PTAFilesystemManager *)manager
                               appendText:(NSString *)text {
  NSParameterAssert(manager);
  NSParameterAssert(text);
  NSParameterAssert(text.length);
  self = [super init];
  if (self) {
    _manager = manager;
    _appendText = [text copy];
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemStop
                                                                                          target:self
                                                                                          action:@selector(didSelectClose:)];
    self.navigationItem.title = @"Select Recipient";
  }
  return self;
}

- (void)loadView {
  _collectionVC = [[PTADocumentCollectionViewController alloc] initWithFilesystemManager:_manager];
  _collectionVC.delegate = self;
  [self addChildViewController:_collectionVC];
  self.view = [[UIView alloc] init];
  [self.view addSubview:_collectionVC.view];
  [_collectionVC didMoveToParentViewController:self];
}

- (void)viewWillLayoutSubviews {
  [super viewWillLayoutSubviews];
  _collectionVC.view.frame = self.view.bounds;
}

- (void)documentCollectionController:(PTADocumentCollectionViewController *)controller
                       didSelectPath:(DBPath *)path {
  NSParameterAssert(controller);
  NSParameterAssert(path);

  NSString *message = [NSString stringWithFormat:@"Added to %@", path.name];
  [self.navigationController.visibleViewController.view.window makeToast:message
                                                                duration:0.5
                                                                position:CSToastPositionCenter];

  [_manager openFileForPath:path];
  [_manager appendString:_appendText toFileAtPath:path];
  [_manager releaseFileForPath:path];
  [self.delegate appendTextControllerDidComplete:self];
}

- (void)didSelectClose:(id)sender {
  [self.delegate appendTextControllerDidComplete:self];
}

@end
