// TODO(mlintz):
//  - if it's downloading, wait for it to finish downloading.

//
//  PTADocumentViewController.m
//  Point
//
//  Created by Mikey Lintz on 9/1/14.
//  Copyright (c) 2014 Mikey Lintz. All rights reserved.
//

#import "PTADocumentViewController.h"

@implementation PTADocumentViewController {
  UITextView *_textView;
  UIActivityIndicatorView *_spinnerView;
  BOOL _isCached;
}

- (void)setFile:(DBFile *)file {
  _file = file;
  if (_file.status.cached) {
    _isCached = YES;
    [self updateView];
//    return;
  }
  __weak id weakSelf = self;
  [_file addObserver:self block:^{
    PTADocumentViewController *strongSelf = weakSelf;
    if (!strongSelf || strongSelf->_isCached || !strongSelf.file.status.cached) {
      return;
    }
    strongSelf->_isCached = YES;
    [strongSelf updateView];
  }];
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
  NSAssert(_file, @"Textview changed but file is nil.");
  NSError *error;
  BOOL successful = [_file writeString:textView.text error:&error];
  NSAssert(successful, error.localizedDescription);
}

#pragma mark - Private

- (void)updateView {
  NSAssert((_isCached && _file.status.cached) || (!_isCached && !_file.status.cached),
           @"_isCached = %c, _file.status.cached = %c", _isCached, _file.status.cached);
  [_textView setEditable:_isCached];
  if (_isCached) {
    [_spinnerView stopAnimating];
  }
  _spinnerView.hidden = _isCached;
  
  if (_isCached) {
    NSError *error;
    NSString *text = [self.file readString:&error];
    _textView.text = text;
  }
}

@end
