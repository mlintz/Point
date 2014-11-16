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
  UIAlertController *_alertController;
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

    self.navigationItem.title = _path.name;
    self.navigationItem.rightBarButtonItem =
        [[PTAComposeBarButtonItem alloc] initWithController:self filesystemManager:_filesystemManager];
  }
  return self;
}

- (void)loadView {
  _textView = [[UITextView alloc] initWithFrame:CGRectZero];
  _textView.delegate = self;

  _spinnerView = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
  [_spinnerView hidesWhenStopped];
  [_spinnerView startAnimating];
  [_textView addSubview:_spinnerView];
  
  self.view = _textView;
}

- (void)viewWillLayoutSubviews {
  [super viewWillLayoutSubviews];
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
  [self dismissAlert];
  if (!_file) {
    // Everything is hidden
  } else if (_file.error) {
    UIAlertAction *action = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleCancel handler:^(UIAlertAction *action) {
      [self.navigationController popViewControllerAnimated:YES];
    }];
    NSString *message = [NSString stringWithFormat:@"File error: %@", _file.error.localizedDescription];
    _alertController = [UIAlertController alertControllerWithTitle:@"Error" message:message preferredStyle:UIAlertControllerStyleAlert];
    [_alertController addAction:action];
  } else if (_file.hasNewerVersion) {
    PTAFilesystemManager *manager = _filesystemManager;
    DBPath *path = _file.info.path;
    UIAlertAction *action = [UIAlertAction actionWithTitle:@"Update" style:UIAlertActionStyleCancel handler:^(UIAlertAction *action) {
      [manager updateFileForPath:path];
    }];
    _alertController = [UIAlertController alertControllerWithTitle:@"Alert" message:@"Newer version of file available" preferredStyle:UIAlertControllerStyleAlert];
    [_alertController addAction:action];
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
  if (_alertController) {
    [self presentViewController:_alertController animated:YES completion:nil];
  }  
}

- (void)dismissAlert {
  [_alertController dismissViewControllerAnimated:YES completion:nil];
  _alertController = nil;
}

@end
