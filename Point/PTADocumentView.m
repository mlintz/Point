//
//  PTADocumentView.m
//  Point
//
//  Created by Mikey Lintz on 11/16/14.
//  Copyright (c) 2014 Mikey Lintz. All rights reserved.
//

#import "PTADocumentView.h"

static const CGFloat kInputBarWidth = 60;

@implementation PTADocumentViewModel

- (instancetype)init {
  return [self initWithLoading:NO text:nil selectedCharacterRange:NSMakeRange(NSNotFound, 0)];
}

- (instancetype)initWithLoading:(BOOL)loading text:(NSString *)text selectedCharacterRange:(NSRange)range {
  self = [super init];
  if (self) {
    _isLoading = loading;
    _text = [text copy];
    _selectedCharacterRange = range;
  }
  return self;
}

@end

@interface PTADocumentView ()<UITextViewDelegate>
@end

@implementation PTADocumentView {
  UITextView *_textView;
  UIActivityIndicatorView *_spinner;
  UIView *_selectionInputBar;
  UIView *_selectionRectangle;
  
  CGRect _keyboardFrame;
  PTADocumentViewModel *_viewModel;
}

- (instancetype)initWithFrame:(CGRect)frame {
  self = [super initWithFrame:frame];
  if (self) {
    _keyboardFrame = CGRectNull;

    _textView = [[UITextView alloc] init];
    _textView.delegate = self;
    UIEdgeInsets textViewInsets = _textView.textContainerInset;
    _textView.textContainerInset =
        UIEdgeInsetsMake(textViewInsets.top, textViewInsets.left, textViewInsets.bottom, textViewInsets.right + kInputBarWidth);
    [self addSubview:_textView];
    
    NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
    [nc addObserverForName:UIKeyboardWillChangeFrameNotification
                    object:nil
                     queue:nil
                usingBlock:^(NSNotification *note) {
                  NSNumber *keyboardFrameValue = note.userInfo[UIKeyboardFrameEndUserInfoKey];
                  _keyboardFrame = [keyboardFrameValue CGRectValue];
                  NSNumber *durationValue = note.userInfo[UIKeyboardAnimationDurationUserInfoKey];
                  [self setNeedsLayout];
                  [UIView animateWithDuration:(CGFloat)durationValue.doubleValue animations:^{
                    [self layoutIfNeeded];
                  }];
                }];
    
    _spinner = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
    _spinner.hidesWhenStopped = YES;
    [_textView addSubview:_spinner];

    _selectionInputBar = [[UIView alloc] init];
    _selectionInputBar.backgroundColor = [UIColor blackColor];
    _selectionInputBar.alpha = 0.1f;
    [self addSubview:_selectionInputBar];

    UIPanGestureRecognizer *panGestureRecognizer =
        [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handleSelectionBarPan:)];
    [_selectionInputBar addGestureRecognizer:panGestureRecognizer];
    
    UITapGestureRecognizer *tapGestureRecognizer =
        [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleSelectionBarTap:)];
    [tapGestureRecognizer requireGestureRecognizerToFail:panGestureRecognizer];
    [_selectionInputBar addGestureRecognizer:tapGestureRecognizer];

    _selectionRectangle = [[UIView alloc] init];
    _selectionRectangle.backgroundColor = [UIColor redColor];
    _selectionRectangle.alpha = 0.25f;
    _selectionRectangle.userInteractionEnabled = NO;
    [_textView addSubview:_selectionRectangle];
  }
  return self;
}

- (void)dealloc {
  [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (NSString *)text {
  return _textView.text;
}

- (void)layoutSubviews {
  if (CGRectIsEmpty(_keyboardFrame)) {
    _textView.frame = self.bounds;
  } else {
    CGRect keyboardFrameInSelf = [self convertRect:_keyboardFrame fromView:self.window];
    CGFloat keyboardTop = CGRectGetMinY(keyboardFrameInSelf);
    CGRect textViewFrame = CGRectMake(0, 0, CGRectGetWidth(self.bounds), keyboardTop);
    _textView.frame = CGRectIntegral(textViewFrame);
  }
  
  [_spinner sizeToFit];
  _spinner.center = CGPointMake(CGRectGetMidX(_textView.bounds), CGRectGetMidY(_textView.bounds));
  
  _selectionInputBar.frame = CGRectMake(CGRectGetWidth(_textView.bounds) - kInputBarWidth,
                                        CGRectGetMinY(_textView.frame),
                                        kInputBarWidth,
                                        CGRectGetHeight(_textView.bounds));

  if (_viewModel.selectedCharacterRange.location == NSNotFound) {
    _selectionRectangle.frame = CGRectMake(0, CGRectGetMidY(_selectionRectangle.frame),
                                           CGRectGetWidth(_textView.bounds), 0);
                                           
  } else {
    CGRect boundingRect = [self fullWidthBoundingRectInTextView:_textView
                                               ofCharacterRange:_viewModel.selectedCharacterRange];
    _selectionRectangle.frame = CGRectIntegral(boundingRect);
  }
}

- (void)textViewDidChange:(UITextView *)textView {
  [self.delegate documentView:self didChangeText:self.text];
}

- (void)setViewModel:(PTADocumentViewModel *)viewModel {
  _viewModel = viewModel;
  if (![_viewModel.text isEqualToString:self.text]) {
    _textView.text = _viewModel.text;
  }

  if (_viewModel.isLoading) {
    [_spinner startAnimating];
  } else {
    [_spinner stopAnimating];
  }

  if (_viewModel.selectedCharacterRange.location != NSNotFound &&
      CGRectGetHeight(_selectionRectangle.bounds) == 0) {
    // Position selection indicator for expand animation.
    CGRect boundingRect = [self fullWidthBoundingRectInTextView:_textView
                                               ofCharacterRange:_viewModel.selectedCharacterRange];
    CGFloat midY = CGRectGetMidY(boundingRect);
    _selectionRectangle.frame = CGRectMake(CGRectGetMinX(boundingRect), midY, CGRectGetWidth(boundingRect), 0);
  }
  [UIView animateWithDuration:0.15f animations:^{
    [self setNeedsLayout];
    [self layoutIfNeeded];
  }];
}

#pragma mark - Private

- (void)handleSelectionBarPan:(UIPanGestureRecognizer *)panRecognizer {
  CGFloat outsideDragThreshold = 15;

  if (panRecognizer.state != UIGestureRecognizerStateBegan &&
      panRecognizer.state != UIGestureRecognizerStateChanged) {
    return;
  }
  [_textView resignFirstResponder];
  CGPoint locationInInputBar = [panRecognizer locationInView:_selectionInputBar];
  if (CGRectGetMinX(_selectionInputBar.bounds) - locationInInputBar.x > outsideDragThreshold) {
    [self.delegate documentViewDidDragToHighlightAllText:self];
    return;
  }
  NSRange selectedCharacterRange = [self characterRangeOfTextView:_textView
                                              lineContainingPoint:[panRecognizer locationInView:_textView]];
  [self.delegate documentView:self didDragToHighlightCharacterRange:selectedCharacterRange];
}

- (void)handleSelectionBarTap:(UITapGestureRecognizer *)tapRecognizer {
  if (tapRecognizer.state == UIGestureRecognizerStateRecognized) {
    [_textView resignFirstResponder];
    [self.delegate documentViewDidTapToCancelSelection:self];
  }
}

- (NSRange)characterRangeOfTextView:(UITextView *)textView lineContainingPoint:(CGPoint)pointInTextView {
  NSParameterAssert(textView);
  CGRect boundingRect = CGRectMake(0, pointInTextView.y, CGRectGetWidth(textView.bounds), 1);
  NSRange glyphRange = [textView.layoutManager glyphRangeForBoundingRect:boundingRect
                                                         inTextContainer:textView.textContainer];
  return [textView.layoutManager characterRangeForGlyphRange:glyphRange actualGlyphRange:NULL];
}

- (CGRect)fullWidthBoundingRectInTextView:(UITextView *)textView
                         ofCharacterRange:(NSRange)characterRange {
  NSParameterAssert(textView);
  NSParameterAssert(characterRange.location != NSNotFound);
  NSRange glyphRange = [textView.layoutManager glyphRangeForCharacterRange:characterRange
                                                      actualCharacterRange:NULL];
  CGRect boundingRectInContainer = [textView.layoutManager boundingRectForGlyphRange:glyphRange
                                                                     inTextContainer:textView.textContainer];
  return CGRectMake(0, CGRectGetMinY(boundingRectInContainer) + textView.textContainerInset.top,
                    CGRectGetWidth(textView.bounds), CGRectGetHeight(boundingRectInContainer));
}

@end
