//
//  PTAQuickComposeViewController.m
//  Point
//
//  Created by Mikey Lintz on 11/14/14.
//  Copyright (c) 2014 Mikey Lintz. All rights reserved.
//

#import "PTAQuickComposeViewController.h"
#import "PTAComposeBarButtonItem.h"
#import "PTAQuickComposeView.h"
#import "PTAAppendTextSelectionViewController.h"
#import "UIView+Toast.h"

static const NSTimeInterval kToastDuration = 0.5;

@interface PTAQuickComposeViewController ()<PTAQuickComposeDelegate, PTAAppendTextSelectionDelegate>
@end

@implementation PTAQuickComposeViewController {
  PTAFilesystemManager *_filesystemManager;
  PTAQuickComposeView *_composeView;
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
    self.navigationItem.title = @"Quick compose";
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemStop target:self action:@selector(handleClose:)];
  }
  return self;
}

- (void)loadView {
  _composeView = [[PTAQuickComposeView alloc] init];
  _composeView.delegate = self;
  self.view = _composeView;
}

- (void)quickComposeViewDidTapAddToInbox:(PTAQuickComposeView *)view withText:(NSString *)text {
  if (!text.length) {
    return;
  }
  [_filesystemManager appendStringToInboxFile:text];
  [self.view.window makeToast:@"Added to Inbox" duration:kToastDuration position:CSToastPositionCenter];
  [self.navigationController dismissViewControllerAnimated:YES completion:nil];
}

- (void)quickComposeViewDidTapAddToOther:(PTAQuickComposeView *)view withText:(NSString *)text {
  if (!text.length) {
    return;
  }

  PTAAppendTextSelectionViewController *appendSelectionController =
      [[PTAAppendTextSelectionViewController alloc] initWithFilesystemManager:_filesystemManager appendText:text];
  appendSelectionController.delegate = self;

  UINavigationController *navigationController =
      [[UINavigationController alloc] initWithRootViewController:appendSelectionController];
  [self presentViewController:navigationController animated:YES completion:nil];
}

- (void)appendTextControllerDidCancel:(PTAAppendTextSelectionViewController *)controller {
  [self.navigationController dismissViewControllerAnimated:YES completion:nil];  // Append selection view controller
}

- (void)appendTextControllerDidComplete:(PTAAppendTextSelectionViewController *)controller
                               withPath:(DBPath *)path {
  [self.navigationController dismissViewControllerAnimated:YES completion:nil];  // Append selection view controller
  [self.navigationController dismissViewControllerAnimated:YES completion:nil];  // Self
}

- (void)handleClose:(id)sender {
  [self.view endEditing:YES];
  [self.navigationController dismissViewControllerAnimated:YES completion:nil];
}

- (void)handleCollectionViewClose:(id)sender {
  [self.navigationController dismissViewControllerAnimated:YES completion:nil];
}

@end
