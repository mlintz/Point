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
    [_textView addGestureRecognizer:_longPressRecognizer];

    _panGestureRecognizer = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handlePan:)];
    _panGestureRecognizer.delegate = self;
    [self addGestureRecognizer:_panGestureRecognizer];
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
  NSAssert(_delegate, @"Delegate cannot be nil.");
  NSAssert(longPressRecognizer == _longPressRecognizer, @"Expecting _longPressRecognizer");
  CGPoint touchLocation = [longPressRecognizer locationInView:_textView];
  NSUInteger characterIndex = [_textView.layoutManager characterIndexForPoint:touchLocation
                                                              inTextContainer:_textView.textContainer
                                     fractionOfDistanceBetweenInsertionPoints:0];
  NSRange selectionRange = [_delegate textEditorView:self
                     selectionRangeForCharacterIndex:characterIndex];
  NSLog(@"touchLocation = %@", NSStringFromCGPoint(touchLocation));
  NSLog(@"characterIndex = %d", characterIndex);
  NSLog(@"selectionString = \"%@\"", [self.text substringWithRange:selectionRange]);
}

- (void)handlePan:(UIPanGestureRecognizer *)panRecognizer {
  NSAssert(panRecognizer == _panGestureRecognizer, @"Expecting _panGestureRecognizer");
  if (panRecognizer.isActive) {
    NSLog(@"Pan!");
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

#pragma mark - Private

@end
