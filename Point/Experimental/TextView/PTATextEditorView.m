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

static NSString *const kDecayAnimationKey = @"com.mikey.PTATextEditorView.decayAnimation";
static NSString *const kSpringAnimationKey = @"com.mikey.PTATextEditorView.springAnimation";

@interface PTATextEditorView ()<UIGestureRecognizerDelegate>
@end

@implementation PTATextEditorView {
  UITextView *_textView;
  UILongPressGestureRecognizer *_longPressRecognizer;
  UIPanGestureRecognizer *_panRecognizer;
  UILabel *_lockLabel;
  UISwitch *_lockSwitch;
  UIImageView *_dragView;
  CGPoint _initialDragCenter;
  BOOL _isDragAndDropActive;
  CGRect _originalTextFrame;
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
    _longPressRecognizer.delegate = self;
    [_textView.panGestureRecognizer requireGestureRecognizerToFail:_longPressRecognizer];
    [self addGestureRecognizer:_longPressRecognizer];

    _panRecognizer = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handlePan:)];
    _panRecognizer.delegate = self;
    [self addGestureRecognizer:_panRecognizer];

    _lockLabel = [[UILabel alloc] init];
    _lockLabel.font = [UIFont systemFontOfSize:16];
    _lockLabel.textColor = [UIColor whiteColor];
    _lockLabel.text = @"Lock";
    [self addSubview:_lockLabel];

    _lockSwitch = [[UISwitch alloc] init];
    [_lockSwitch addTarget:self action:@selector(handleSwitch:) forControlEvents:UIControlEventValueChanged];
    [self addSubview:_lockSwitch];

    _dragView = [[UIImageView alloc] init];
    _dragView.hidden = YES;
    [self addSubview:_dragView];

    [self updateTextView];
  }
  return self;
}

- (NSString *)text {
  return _textView.text;
}

- (void)setText:(NSString *)text {
  _textView.text = text;
}

#pragma mark - UIResponder

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
  [super touchesBegan:touches withEvent:event];
  if ([_textView canResignFirstResponder]) {
    [_textView resignFirstResponder];
  }
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
  [self updateTextView];

  switch (longPressRecognizer.state) {
    case UIGestureRecognizerStateBegan: {
      [_dragView pop_removeAllAnimations];
      _isDragAndDropActive = NO;
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
      if (!_isDragAndDropActive) {
        _dragView.hidden = YES;
      }
      break;
    }
    default:
      break;
  }
}

- (void)handlePan:(UIPanGestureRecognizer *)panRecognizer {
  switch (panRecognizer.state) {
    case UIGestureRecognizerStateBegan: {
      _isDragAndDropActive = YES;
      _initialDragCenter = _dragView.center;
      _originalTextFrame = _dragView.frame;
      break;
    }
    case UIGestureRecognizerStateChanged: {
      _dragView.center = PTAPointAdd([panRecognizer translationInView:self], _initialDragCenter);
      break;
    }
    case UIGestureRecognizerStateEnded:
    case UIGestureRecognizerStateCancelled: {
      POPDecayAnimation *decayAnimation =
          [POPDecayAnimation animationWithPropertyNamed:kPOPLayerPosition];
      decayAnimation.velocity = [NSValue valueWithCGPoint:[panRecognizer velocityInView:self]];
      CGFloat decayRate = 0.99f;
      decayAnimation.deceleration = decayRate;
      [decayAnimation setCompletionBlock:^(POPAnimation *animation, BOOL completed) {
        if (CGRectIntersectsRect(self.bounds, _dragView.frame)) {
          POPSpringAnimation *springAnimation = [POPSpringAnimation animationWithPropertyNamed:kPOPViewFrame];
          springAnimation.toValue = [NSValue valueWithCGRect:_originalTextFrame];
          [springAnimation setCompletionBlock:^(POPAnimation *animation, BOOL completed) {
            _dragView.hidden = YES;
          }];
          [_dragView pop_addAnimation:springAnimation forKey:kSpringAnimationKey];
        }
      }];
      [_dragView pop_addAnimation:decayAnimation forKey:kDecayAnimationKey];
      break;
    }
    default:
      break;
  }
}

- (BOOL)gestureRecognizerShouldBegin:(UIGestureRecognizer *)gestureRecognizer {
  NSAssert(gestureRecognizer == _longPressRecognizer || gestureRecognizer == _panRecognizer, @"Unknown gestureRecognizer: %@", gestureRecognizer);

  if (gestureRecognizer == _panRecognizer) {
    return _longPressRecognizer.pta_isActive;
  }
  if (gestureRecognizer == _longPressRecognizer && [self isLongPressEnabled]) {
    CGPoint touchLocation = [_longPressRecognizer locationInView:_textView];
    NSUInteger characterIndex = [_textView.layoutManager characterIndexForPoint:touchLocation
                                                                inTextContainer:_textView.textContainer
                                       fractionOfDistanceBetweenInsertionPoints:0];
    return [_delegate textEditorView:self shouldStartSelectionAtCharacterIndex:characterIndex];
  }
  return NO;
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer
    shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherRecognizer {
  if (gestureRecognizer == _longPressRecognizer || otherRecognizer == _longPressRecognizer) {
    return YES;
  }
  if (gestureRecognizer == _panRecognizer || otherRecognizer == _panRecognizer) {
    return YES;
  }

  return NO;
}

#pragma mark - Target-action

- (void)handleSwitch:(UISwitch *)switchView {
  [self updateTextView];
}

#pragma mark - Private

- (BOOL)isLongPressEnabled {
  return _lockSwitch.isOn;
}

- (void)updateTextView {
  _textView.selectable = !_lockSwitch.isOn;
  _textView.editable = !_lockSwitch.isOn;
  _textView.textColor = _lockSwitch.isOn ? [UIColor lightGrayColor] : [UIColor darkTextColor];
//  [_textView setScrollEnabled:!_longPressRecognizer.isActive];
//  _textView.userInteractionEnabled = !_longPressRecognizer.isActive;
}

@end
