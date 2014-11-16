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
#import "PTADocumentCollectionViewController.h"
#import "UIView+Toast.h"

static const NSTimeInterval kToastDuration = 0.5;

@interface PTAQuickComposeViewController ()<PTAQuickComposeDelegate, PTADocumentCollectionDelegate>
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
  [_filesystemManager appendTextToInboxFile:text];
  [self.view.window makeToast:@"Added to Inbox" duration:kToastDuration position:CSToastPositionCenter];
  [self.navigationController dismissViewControllerAnimated:YES completion:nil];
}

- (void)quickComposeViewDidTapAddToOther:(PTAQuickComposeView *)view withText:(NSString *)text {
  if (!text.length) {
    return;
  }
  PTADocumentCollectionViewController *documentCollectionVC =
      [[PTADocumentCollectionViewController alloc] initWithFilesystemManager:_filesystemManager];
  documentCollectionVC.delegate = self;
  documentCollectionVC.navigationItem.title = @"Select Recipient";
  documentCollectionVC.navigationItem.leftBarButtonItem =
      [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemStop
                                                    target:self
                                                    action:@selector(handleCollectionViewClose:)];
  UINavigationController *navigationController =
      [[UINavigationController alloc] initWithRootViewController:documentCollectionVC];
  [self presentViewController:navigationController animated:YES completion:nil];
}

- (void)documentCollectionController:(PTADocumentCollectionViewController *)controller
                       didSelectPath:(DBPath *)path {
  NSParameterAssert(controller);
  NSParameterAssert(path);

  NSString *message = [NSString stringWithFormat:@"Added to %@", path.name];
  [self.navigationController.visibleViewController.view.window makeToast:message
                                                                duration:kToastDuration position:CSToastPositionCenter];

  [self.navigationController dismissViewControllerAnimated:YES completion:nil];  // Dismiss collection controller
  if (!_composeView.text.length) {
    return;
  }
  [_filesystemManager openFileForPath:path];
  [_filesystemManager appendString:_composeView.text toFileAtPath:path];
  [_filesystemManager releaseFileForPath:path];
  [self.navigationController dismissViewControllerAnimated:YES completion:nil];  // Dismiss self
}

- (void)handleClose:(id)sender {
  [self.view endEditing:YES];
  [self.navigationController dismissViewControllerAnimated:self completion:nil];
}

- (void)handleCollectionViewClose:(id)sender {
  [self.navigationController dismissViewControllerAnimated:self completion:nil];
}

@end
