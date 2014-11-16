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
#import "PTAComposeBarButtonItem.h"

@interface PTADocumentViewController ()<UITextViewDelegate, PTAFileObserver>
@end

@implementation PTADocumentViewController {
  UITextView *_textView;
  UIActivityIndicatorView *_spinnerView;
  BOOL _isCached;
  DBPath *_path;
  PTAFile *_file;
  PTAFilesystemManager *_filesystemManager;
  UIAlertController *_newVersionAlertController;
  UIAlertController *_errorAlertController;
  
  CGRect _keyboardFrame;
}

- (instancetype)init {
  [self doesNotRecognizeSelector:_cmd];
  return nil;
}

- (instancetype)initWithManager:(PTAFilesystemManager *)manager path:(DBPath *)path {
  NSParameterAssert(manager);
  NSParameterAssert(path);
  self = [super init];
  if (self) {
    _filesystemManager = manager;
    _path = path;
    _keyboardFrame = CGRectNull;

    self.navigationItem.title = _path.name;
    self.navigationItem.rightBarButtonItem =
        [[PTAComposeBarButtonItem alloc] initWithController:self filesystemManager:_filesystemManager];

    __weak id weakSelf = self;
    UIAlertAction *action;
    action = [UIAlertAction actionWithTitle:@"OK"
                                      style:UIAlertActionStyleCancel
                                    handler:^(UIAlertAction *action) {
      [[weakSelf navigationController] popViewControllerAnimated:YES];
    }];
    NSString *message = [NSString stringWithFormat:@"File error: %@", _file.error.localizedDescription];
    _errorAlertController = [UIAlertController alertControllerWithTitle:@"Error"
                                                                message:message
                                                         preferredStyle:UIAlertControllerStyleAlert];
    [_errorAlertController addAction:action];

    action = [UIAlertAction actionWithTitle:@"Update"
                                      style:UIAlertActionStyleCancel
                                    handler:^(UIAlertAction *action) {
      [manager updateFileForPath:path];
    }];
    _newVersionAlertController = [UIAlertController alertControllerWithTitle:@"Alert"
                                                                     message:@"Newer version of file available"
                                                              preferredStyle:UIAlertControllerStyleAlert];
    [_newVersionAlertController addAction:action];

    NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
    [nc addObserverForName:UIKeyboardWillChangeFrameNotification
                    object:nil
                     queue:nil
                usingBlock:^(NSNotification *note) {
      NSNumber *keyboardFrameValue = note.userInfo[UIKeyboardFrameEndUserInfoKey];
      _keyboardFrame = [keyboardFrameValue CGRectValue];
      NSNumber *durationValue = note.userInfo[UIKeyboardAnimationDurationUserInfoKey];
      if (self.isViewLoaded) {
        [self.view setNeedsLayout];
        [UIView animateWithDuration:(CGFloat)durationValue.doubleValue animations:^{
          [self.view layoutIfNeeded];
        }];
      }
    }];
  }
  return self;
}

- (void)dealloc {
  [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)loadView {
  self.view = [[UIView alloc] init];

  _textView = [[UITextView alloc] initWithFrame:CGRectZero];
  _textView.delegate = self;
  [self.view addSubview:_textView];

  _spinnerView = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
  [_spinnerView hidesWhenStopped];
  [_spinnerView startAnimating];
  [self.view addSubview:_spinnerView];
}

- (void)viewWillLayoutSubviews {
  [super viewWillLayoutSubviews];
  if (CGRectIsEmpty(_keyboardFrame)) {
    _textView.frame = self.view.bounds;
  } else {
    CGRect keyboardFrameInView = [self.view convertRect:_keyboardFrame fromView:self.view.window];
    CGFloat keyboardTop = CGRectGetMinY(keyboardFrameInView);
    _textView.frame = CGRectMake(0, 0, CGRectGetWidth(self.view.bounds), keyboardTop);
  }

  [_spinnerView sizeToFit];
  _spinnerView.center = _textView.center;
}

- (void)viewWillAppear:(BOOL)animated {
  [super viewWillAppear:animated];
  [_filesystemManager addFileObserver:self forPath:_path];
  _file = [_filesystemManager openFileForPath:_path];
  NSAssert(!_file.error, @"Error opening file: %@", _file.error);

  [self updateView];
}

- (void)viewDidAppear:(BOOL)animated {
  [super viewDidAppear:animated];
//  [_textView becomeFirstResponder];
}

- (void)viewDidDisappear:(BOOL)animated {
  [super viewDidDisappear:animated];
  [_filesystemManager removeFileObserver:self forPath:_path];
  [_filesystemManager releaseFileForPath:_path];
  _file = nil;
  [self updateView];
}

#pragma mark - UITextViewDelegate

- (void)textViewDidChange:(UITextView *)textView {
  [_filesystemManager writeString:textView.text toFileAtPath:_file.info.path];
}

#pragma mark - PTAFileObserver

- (void)fileDidChange:(PTAFile *)file {
  NSAssert(file, @"file must be non-nil.");
  _file = file;
  [self updateView];
}

#pragma mark - Private

- (void)updateView {
  BOOL isTextViewHidden = YES;
  BOOL isSpinnerHidden = YES;
  BOOL isNewVersionAlertVisible = NO;
  BOOL isErrorAlertVisible = NO;
  if (!_file) {
    // Everything is hidden
  } else if (_file.error) {
    isErrorAlertVisible = YES;
  } else if (_file.hasNewerVersion) {
    isNewVersionAlertVisible = YES;
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

  if (isNewVersionAlertVisible && !_newVersionAlertController.view.window) {
    [self presentViewController:_newVersionAlertController animated:YES completion:nil];
  } else if (!isNewVersionAlertVisible && _newVersionAlertController.view.window) {
    [self dismissViewControllerAnimated:YES completion:nil];
  }
  
  if (isErrorAlertVisible && !_errorAlertController.view.window) {
    [self presentViewController:_errorAlertController animated:YES completion:nil];
  } else if (!isErrorAlertVisible && _errorAlertController.view.window) {
    [self dismissViewControllerAnimated:YES completion:nil];
  }
}

@end
