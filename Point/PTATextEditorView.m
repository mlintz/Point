//
//  PTATextEditorView.m
//  Point
//
//  Created by Mikey Lintz on 7/4/14.
//  Copyright (c) 2014 Mikey Lintz. All rights reserved.
//

#import "PTATextEditorView.h"

#import <POP/POP.h>

static NSString *const kFontName = @"CourierNewPSMT";
static CGFloat const kFontSize = 16.f;

static CGFloat const kVerticalPadding = 16.f;
static CGFloat const kHorizontalPadding = 16.f;

@interface PTATextEditorView ()<UIGestureRecognizerDelegate>
@end

@implementation PTATextEditorView {
  UITextView *_textView;
  UILongPressGestureRecognizer *_longPressRecognizer;
  UILabel *_lockLabel;
  UISwitch *_lockSwitch;
  UIImageView *_dragView;
}

@synthesize delegate = _delegate;

- (id)initWithFrame:(CGRect)frame {
  self = [super initWithFrame:frame];
  if (self) {
    self.backgroundColor = [UIColor darkGrayColor];

    _textView = [[UITextView alloc] init];
    _textView.font = [UIFont fontWithName:kFontName size:kFontSize];
    _textView.selectable = NO;
    [self addSubview:_textView];

    _longPressRecognizer = [[UILongPressGestureRecognizer alloc] initWithTarget:self
                                                                         action:@selector(handleLongPress:)];
    _longPressRecognizer.delegate = self;
    [_textView addGestureRecognizer:_longPressRecognizer];

    _dragView = [[UIImageView alloc] init];
    _dragView.hidden = YES;
    [self addSubview:_dragView];

    _lockLabel = [[UILabel alloc] init];
    _lockLabel.font = [UIFont systemFontOfSize:16];
    _lockLabel.textColor = [UIColor whiteColor];
    _lockLabel.text = @"Lock";
    [self addSubview:_lockLabel];

    _lockSwitch = [[UISwitch alloc] init];
    [self addSubview:_lockSwitch];
  }
  return self;
}

- (NSString *)text {
  return _textView.text;
}

- (void)setText:(NSString *)text {
  _textView.text = text;
}

#pragma mark - UIView

- (void)layoutSubviews {
  [super layoutSubviews];
  CGRect dummyRect;

  CGRect contentRect = CGRectInset(self.bounds, kHorizontalPadding, kVerticalPadding);

  [_lockSwitch sizeToFit];
  [_lockLabel sizeToFit];
  CGFloat footerHeight = MAX(CGRectGetHeight(_lockLabel.bounds), CGRectGetHeight(_lockSwitch.bounds)) + kVerticalPadding;
  
  CGRect footerRect;
  CGRect textViewRect;
  CGRectDivide(contentRect, &footerRect, &textViewRect, footerHeight, CGRectMaxYEdge);

  _textView.frame = CGRectIntegral(textViewRect);

  CGRectDivide(footerRect, &dummyRect, &footerRect, kVerticalPadding, CGRectMinYEdge);

  CGRect labelRect;
  CGRect switchRect;
  CGRectDivide(footerRect, &labelRect, &switchRect, CGRectGetWidth(_lockLabel.bounds), CGRectMinXEdge);

  _lockLabel.frame = CGRectIntegral(labelRect);
  
  CGRectDivide(switchRect, &switchRect, &dummyRect, CGRectGetWidth(_lockSwitch.bounds), CGRectMinXEdge);
  _lockSwitch.frame = CGRectIntegral(CGRectOffset(switchRect, kHorizontalPadding, 0));
}

#pragma mark - Gesture

- (void)handleLongPress:(UILongPressGestureRecognizer *)longPressRecognizer {
  // XXX(mlintz); this can get refactored into several methods

  NSAssert(_delegate, @"Delegate cannot be nil.");
  NSAssert(longPressRecognizer == _longPressRecognizer, @"Expecting _longPressRecognizer");

  switch (longPressRecognizer.state) {
    case UIGestureRecognizerStateBegan: {
      CGPoint touchLocation = [longPressRecognizer locationInView:_textView];
      NSUInteger characterIndex = [_textView.layoutManager characterIndexForPoint:touchLocation
                                                                  inTextContainer:_textView.textContainer
                                         fractionOfDistanceBetweenInsertionPoints:0];
      NSRange selectionCharacterRange = [_delegate textEditorView:self
                                  selectionRangeForCharacterIndex:characterIndex];
      NSRange glyphRange = [_textView.layoutManager glyphRangeForCharacterRange:selectionCharacterRange
                                                           actualCharacterRange:NULL];
      CGRect boundingBox = [_textView.layoutManager boundingRectForGlyphRange:glyphRange
                                                              inTextContainer:_textView.textContainer];
      boundingBox = CGRectIntegral(boundingBox);
      boundingBox = CGRectOffset(boundingBox, _textView.textContainerInset.left, _textView.textContainerInset.top);
      
      UIColor *backgroundColor = _textView.backgroundColor;
      _textView.backgroundColor = [UIColor clearColor];
      UIImage *snapshot = [_textView snapshotCroppedToRect:boundingBox];
      _textView.backgroundColor = backgroundColor;
      
      _dragView.image = snapshot;
      _dragView.backgroundColor = [UIColor purpleColor];
      [_dragView sizeToFit];
      _dragView.hidden = NO;
      _dragView.frame = [self convertRect:boundingBox fromView:_textView];
      
      NSLog(@"selectionString = \"%@\"", [self.text substringWithRange:selectionCharacterRange]);
      NSLog(@"used rect = %@", NSStringFromCGRect([_textView.layoutManager usedRectForTextContainer:_textView.textContainer]));
      break;
    }
    case UIGestureRecognizerStateEnded:
    case UIGestureRecognizerStateCancelled: {
      break;
    }
    default:
      break;
  }
}

- (BOOL)gestureRecognizerShouldBegin:(UIGestureRecognizer *)gestureRecognizer {
  if (gestureRecognizer == _longPressRecognizer) {
    CGPoint touchLocation = [_longPressRecognizer locationInView:_textView];
    NSUInteger characterIndex = [_textView.layoutManager characterIndexForPoint:touchLocation
                                                                inTextContainer:_textView.textContainer
                                       fractionOfDistanceBetweenInsertionPoints:0];
    return [_delegate textEditorView:self shouldStartSelectionAtCharacterIndex:characterIndex];
  }
  if (gestureRecognizer == _panGestureRecognizer) {
    return _longPressRecognizer.isActive;
  }
  NSAssert(NO, @"Unknown gestureRecognizer: %@", gestureRecognizer);
  return NO;
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer
    shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherRecognizer {
  if (gestureRecognizer == _longPressRecognizer || otherRecognizer == _longPressRecognizer) {
    return YES;
  }
  if (gestureRecognizer == _panGestureRecognizer || otherRecognizer == _panGestureRecognizer) {
    return YES;
  }
  return NO;
}

#pragma mark - Private

@end
