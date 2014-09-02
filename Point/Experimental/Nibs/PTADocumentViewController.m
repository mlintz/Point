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
}

- (void)setTitle:(NSString *)title {
  self.navigationItem.title = title;
}

- (void)setText:(NSString *)text {
  _text = text;
  _textView.text = text;
}

- (void)loadView {
  _textView = [[UITextView alloc] initWithFrame:CGRectZero];
  _textView.text = _text;
  self.view = _textView;
}

@end
