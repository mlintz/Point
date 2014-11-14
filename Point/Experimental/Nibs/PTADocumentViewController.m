// TODO(mlintz):

//
//  PTADocumentViewController.m
//  Point
//
//  Created by Mikey Lintz on 9/1/14.
//  Copyright (c) 2014 Mikey Lintz. All rights reserved.
//

#import "PTADocumentViewController.h"
#import "PTAFile.h"
#import "PTAFileInfo.h"
#import "PTAFilesystemManager.h"

@interface PTADocumentViewController ()<UITextViewDelegate, PTAFileObserver>
@end

@implementation PTADocumentViewController {
  UITextView *_textView;
  UIActivityIndicatorView *_spinnerView;
  BOOL _isCached;
  PTAFile *_file;
  PTAFilesystemManager *_filesystemManager;
}

- (instancetype)init {
  [self doesNotRecognizeSelector:_cmd];
  return nil;
}

- (instancetype)initWithManager:(PTAFilesystemManager *)manager path:(DBPath *)path {
  NSAssert(manager && path, @"manager (%@) and path (%@) must be non-nil.", manager, path);
  self = [super init];
  if (self) {
    _filesystemManager = manager;
    [_filesystemManager addFileObserver:self forPath:path];
    _file = [_filesystemManager openFileForPath:path];
    NSAssert(!_file.error, @"Error opening file: %@", _file.error);
  }
  return self;
}

- (void)dealloc {
  [_filesystemManager closeFileForPath:_file.info.path];
}

- (void)loadView {
  _textView = [[UITextView alloc] initWithFrame:CGRectZero];
  _textView.delegate = self;

  _spinnerView = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
  [_spinnerView hidesWhenStopped];
  [_spinnerView startAnimating];
  [_textView addSubview:_spinnerView];
  
  self.view = _textView;
  [self updateView];
}

- (void)viewWillLayoutSubviews {
  [super viewWillLayoutSubviews];
  [_spinnerView sizeToFit];
  _spinnerView.center = _textView.center;
}

#pragma mark - UITextViewDelegate

- (void)textViewDidChange:(UITextView *)textView {
  [_filesystemManager writeString:textView.text toFileAtPath:_file.info.path];
}

#pragma mark - PTAFileObserver

- (void)fileDidChange:(PTAFile *)file {
  NSAssert(file, @"file must be non-nil.");
  [self.navigationController popToViewController:self animated:YES];
  _file = file;
  [self updateView];
}

#pragma mark - Private

- (void)updateView {
  BOOL isTextViewHidden = YES;
  BOOL isSpinnerHidden = YES;
  UIAlertController *alertController;
  if (_file.error) {
    UIAlertAction *action = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleCancel handler:^(UIAlertAction *action) {
      [self.navigationController popViewControllerAnimated:YES];
    }];
    NSString *message = [NSString stringWithFormat:@"File error: %@", _file.error.localizedDescription];
    alertController = [UIAlertController alertControllerWithTitle:@"Error" message:message preferredStyle:UIAlertControllerStyleAlert];
    [alertController addAction:action];
  } else if (_file.hasNewerVersion) {
    PTAFilesystemManager *manager = _filesystemManager;
    DBPath *path = _file.info.path;
    UIAlertAction *action = [UIAlertAction actionWithTitle:@"Update" style:UIAlertActionStyleCancel handler:^(UIAlertAction *action) {
      [manager updateFileForPath:path];
    }];
    alertController = [UIAlertController alertControllerWithTitle:@"Alert" message:@"Newer version of file available" preferredStyle:UIAlertControllerStyleAlert];
    [alertController addAction:action];
  } else if (!_file.isOpen || !_file.cached) {
    isSpinnerHidden = NO;
  } else {
    if (![_file.content isEqualToString:_textView.text]) {
      _textView.text = _file.content;
    }
    isTextViewHidden = NO;
  }
  _textView.hidden = isTextViewHidden;
  if (isSpinnerHidden) {
    [_spinnerView stopAnimating];
  } else {
    [_spinnerView startAnimating];
  }
  if (alertController) {
    [self presentViewController:alertController animated:YES completion:nil];
  }  
}

@end
