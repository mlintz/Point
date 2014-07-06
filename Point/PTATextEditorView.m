//
//  PTATextEditorView.m
//  Point
//
//  Created by Mikey Lintz on 7/4/14.
//  Copyright (c) 2014 Mikey Lintz. All rights reserved.
//

#import "PTATextEditorView.h"

static NSString *const kFontName = @"CourierNewPSMT";
static CGFloat const kFontSize = 16.f;

static CGFloat const kVerticalPadding = 16.f;
static CGFloat const kHorizontalPadding = 16.f;

@interface PTATextEditorView ()<UIGestureRecognizerDelegate>
@end

@implementation PTATextEditorView {
  UITextView *_textView;
  UILongPressGestureRecognizer *_longPressRecognizer;
  UIPanGestureRecognizer *_panGestureRecognizer;
  UIImageView *_dragView;
}

@synthesize delegate = _delegate;

- (id)initWithFrame:(CGRect)frame {
  self = [super initWithFrame:frame];
  if (self) {
    self.backgroundColor = [UIColor darkGrayColor];

    _textView = [[UITextView alloc] init];
    _textView.font = [UIFont fontWithName:kFontName size:kFontSize];
    [self addSubview:_textView];

    _longPressRecognizer = [[UILongPressGestureRecognizer alloc] initWithTarget:self
                                                                         action:@selector(handleLongPress:)];
//    _longPressRecognizer.cancelsTouchesInView = NO;
    _longPressRecognizer.delegate = self;
    [_textView addGestureRecognizer:_longPressRecognizer];

    _panGestureRecognizer = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handlePan:)];
//    _panGestureRecognizer.cancelsTouchesInView = NO;
    _panGestureRecognizer.delegate = self;
    [_textView addGestureRecognizer:_panGestureRecognizer];

    _dragView = [[UIImageView alloc] init];
    _dragView.hidden = YES;
    [self addSubview:_dragView];
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

  _textView.frame = CGRectInset(self.bounds, kHorizontalPadding, kVerticalPadding);
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
      //  UIColor *textColor = _textView.textColor;
      _textView.backgroundColor = [UIColor clearColor];
      //  _textView.textColor = [UIColor redColor];
      UIImage *snapshot = [_textView snapshotCroppedToRect:boundingBox];
      _textView.backgroundColor = backgroundColor;
      //  _textView.textColor = textColor;
      
      _dragView.image = snapshot;
      _dragView.backgroundColor = [UIColor purpleColor];
      [_dragView sizeToFit];
      _dragView.hidden = NO;
      _dragView.frame = [self convertRect:boundingBox fromView:_textView];
      
      //  NSLog(@"touchLocation = %@", NSStringFromCGPoint(touchLocation));
      //  NSLog(@"characterIndex = %d", characterIndex);
      NSLog(@"selectionString = \"%@\"", [self.text substringWithRange:selectionCharacterRange]);
      NSLog(@"used rect = %@", NSStringFromCGRect([_textView.layoutManager usedRectForTextContainer:_textView.textContainer]));
      break;
    }
    case UIGestureRecognizerStateEnded:
    case UIGestureRecognizerStateCancelled: {
      if (!_panGestureRecognizer.isActive) {
        _dragView.hidden = YES;
      }
      break;
    }
    default:
      break;
  }
}

- (void)handlePan:(UIPanGestureRecognizer *)panRecognizer {
  NSAssert(panRecognizer == _panGestureRecognizer, @"Expecting _panGestureRecognizer");

  switch (panRecognizer.state) {
//    case UIGestureRecognizerStateBegan: {
//      _initialDragPosition = [panRecognizer locationInView:self];
//      break;
//    }
    case UIGestureRecognizerStateChanged: {
      CGPoint translation = [panRecognizer translationInView:self];
      CGAffineTransform transform = CGAffineTransformMakeTranslation(translation.x, translation.y);
      _dragView.transform = transform;
      break;
    }
    case UIGestureRecognizerStateEnded: {
      _dragView.transform = CGAffineTransformIdentity;
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
