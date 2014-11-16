//
//  PTAQuickComposeView.m
//  Point
//
//  Created by Mikey Lintz on 11/15/14.j
//  Copyright (c) 2014 Mikey Lintz. All rights reserved.
//

#import "PTAQuickComposeView.h"

@implementation PTAQuickComposeView {
  UITextView *_textView;
  UIButton *_addToInboxButton;
  UIButton *_addToOtherButton;
}

- (instancetype)initWithFrame:(CGRect)frame {
  self = [super initWithFrame:frame];
  if (self) {
    self.backgroundColor = [UIColor whiteColor];
  
    UITapGestureRecognizer *tapRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleViewTapped:)];
    [self addGestureRecognizer:tapRecognizer];
    
    UIEdgeInsets buttonInset = UIEdgeInsetsMake(16, 0, 16, 0);

    _textView = [[UITextView alloc] init];
    _textView.backgroundColor = [UIColor lightGrayColor];
    [self addSubview:_textView];
    
    _addToInboxButton = [UIButton buttonWithType:UIButtonTypeCustom];
    _addToInboxButton.backgroundColor = [UIColor lightGrayColor];
    [_addToInboxButton setTitle:@"Add to Inbox" forState:UIControlStateNormal];
    [_addToInboxButton setTitleColor:[UIColor blueColor] forState:UIControlStateNormal];
    _addToInboxButton.contentEdgeInsets = buttonInset;
    [_addToInboxButton addTarget:self
                          action:@selector(handleInboxButtonTapped:)
                forControlEvents:UIControlEventTouchUpInside];
    [self addSubview:_addToInboxButton];
    
    _addToOtherButton = [UIButton buttonWithType:UIButtonTypeCustom];
    _addToOtherButton.backgroundColor = [UIColor lightGrayColor];
    [_addToOtherButton setTitle:@"Add to ..." forState:UIControlStateNormal];
    [_addToOtherButton setTitleColor:[UIColor darkTextColor] forState:UIControlStateNormal];
    _addToOtherButton.contentEdgeInsets = buttonInset;
    [_addToOtherButton addTarget:self
                          action:@selector(handleOtherButtonTapped:)
                forControlEvents:UIControlEventTouchUpInside];
    [self addSubview:_addToOtherButton];
  }
  return self;
}

- (void)layoutSubviews {
  CGFloat padding = 16;
  
  CGFloat buttonHeight = MAX([_addToInboxButton sizeThatFits:self.bounds.size].height,
                             [_addToOtherButton sizeThatFits:self.bounds.size].height);
  _addToOtherButton.frame = CGRectIntegral(CGRectMake(0, CGRectGetMaxY(self.bounds) - padding - buttonHeight,
                                                      CGRectGetWidth(self.bounds), buttonHeight));
  _addToInboxButton.frame = CGRectIntegral(CGRectOffset(_addToOtherButton.frame, 0, -padding - buttonHeight));

  _textView.frame = CGRectMake(0, 0, CGRectGetWidth(self.bounds), 200);
}

- (void)handleInboxButtonTapped:(id)sender {
  [self.delegate quickComposeViewdidTapAddToInbox:self withText:_textView.text];
}

- (void)handleOtherButtonTapped:(id)sender {
  [self.delegate quickComposeViewdidTapAddToOther:self withText:_textView.text];
}

- (void)handleViewTapped:(UITapGestureRecognizer *)recognizer {
  if (recognizer.state == UIGestureRecognizerStateRecognized) {
    [_textView resignFirstResponder];
  }
}

@end
