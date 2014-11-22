//
//  PTADocumentView.m
//  Point
//
//  Created by Mikey Lintz on 11/16/14.
//  Copyright (c) 2014 Mikey Lintz. All rights reserved.
//

#import "PTADocumentView.h"
#import "PTASelectionManager.h"

static const CGFloat kInputBarWidth = 60;
static const CGFloat kSelectionRectVerticalPadding = 30;

@interface NSString (PTASelection)
- (NSString *)pta_stringByApplyingTransform:(PTASelectionTransform *)transform
                 withSelectedCharacterRange:(NSRange)selectedCharacterRange;
- (NSString *)pta_stringByUnapplyingTransform:(PTASelectionTransform *)transform
                 withSelectedCharacterRange:(NSRange)selectedCharacterRange;
@end

@implementation NSString (PTASelection)

- (NSString *)pta_stringByApplyingTransform:(PTASelectionTransform *)transform
                 withSelectedCharacterRange:(NSRange)selectedCharacterRange {
  NSString *selectedText = [self substringWithRange:selectedCharacterRange];
  NSString *stringWithoutSelectedCharacters =
      [self stringByReplacingCharactersInRange:selectedCharacterRange
                                    withString:@""];
  NSRange insertionRange = NSMakeRange(transform.insertionLocation, 0);
  return [stringWithoutSelectedCharacters stringByReplacingCharactersInRange:insertionRange
                                                                  withString:selectedText];
}

- (NSString *)pta_stringByUnapplyingTransform:(PTASelectionTransform *)transform
                   withSelectedCharacterRange:(NSRange)selectedCharacterRange {
  NSRange range = NSMakeRange(transform.insertionLocation, selectedCharacterRange.length);
  NSString *selectedText = [self substringWithRange:range];
  NSString *stringWithoutSelectedCharacters = [self stringByReplacingCharactersInRange:range withString:@""];
  return [stringWithoutSelectedCharacters stringByReplacingCharactersInRange:NSMakeRange(selectedCharacterRange.location, 0)
                                                                  withString:selectedText];
}

@end

@implementation PTADocumentViewModel

- (instancetype)init {
  return [self initWithLoading:NO text:nil selectedCharacterRange:PTANullRange];
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

- (BOOL)isEqual:(id)object {
  if (![object isKindOfClass:[self class]]) {
    return NO;
  }
  PTADocumentViewModel *other = object;
  return _isLoading == other.isLoading
      && NSEqualRanges(_selectedCharacterRange, other.selectedCharacterRange)
      && [_text isEqualToString:other.text];
}

- (NSUInteger)hash {
  return (_isLoading ? 1 : 0) ^ [_text hash] ^ PTARangeHash(_selectedCharacterRange);
}

@end

@interface PTADocumentView ()<UITextViewDelegate, UIGestureRecognizerDelegate>
@end

@implementation PTADocumentView {
  UITextView *_textView;
  UIActivityIndicatorView *_spinner;
  UIView *_selectionInputBar;
  UIView *_selectionRectangle;

  UIPanGestureRecognizer *_selectionRectPanRecognizer;

  CGRect _keyboardFrame;
  PTADocumentViewModel *_viewModel;

  PTASelectionManager *_selectionManager;
  PTASelectionTransform *_selectionTransform;
}

- (instancetype)initWithFrame:(CGRect)frame {
  self = [super initWithFrame:frame];
  if (self) {
    _keyboardFrame = CGRectNull;

    _textView = [[UITextView alloc] init];
    _textView.delegate = self;
    _textView.font = [UIFont systemFontOfSize:16];
    UIEdgeInsets textViewInsets = _textView.textContainerInset;
    _textView.textContainerInset =
        UIEdgeInsetsMake(textViewInsets.top, textViewInsets.left, textViewInsets.bottom, textViewInsets.right + kInputBarWidth);
    [self addSubview:_textView];
    
    _selectionRectPanRecognizer = [[UIPanGestureRecognizer alloc] initWithTarget:self
                                                                          action:@selector(handleSelectionRectPan:)];
    _selectionRectPanRecognizer.delegate = self;
    [_textView addGestureRecognizer:_selectionRectPanRecognizer];
    
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
  if (!_selectionTransform || PTARangeEmptyOrNotFound(_viewModel.selectedCharacterRange)) {
    return _textView.text;
  }
  return [_textView.text pta_stringByUnapplyingTransform:_selectionTransform
                              withSelectedCharacterRange:_viewModel.selectedCharacterRange];
}

- (void)setViewModel:(PTADocumentViewModel *)viewModel {
  NSParameterAssert(viewModel);
  if ([_viewModel isEqual:viewModel]) {
    return;
  }

  _viewModel = viewModel;
  if (![_viewModel.text isEqualToString:self.text]) {
    _textView.text = _viewModel.text;
  }

  if (_viewModel.isLoading) {
    [_spinner startAnimating];
  } else {
    [_spinner stopAnimating];
  }

  if (!PTARangeEmptyOrNotFound(_viewModel.selectedCharacterRange) &&
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
  
  [self updateSelectionTransform:nil];
}

#pragma mark - UIView

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

  if (PTARangeEmptyOrNotFound(_viewModel.selectedCharacterRange)) {
    _selectionRectangle.frame = CGRectMake(0, CGRectGetMidY(_selectionRectangle.frame),
                                           CGRectGetWidth(_textView.bounds), 0);
                                           
  } else {
    CGRect boundingRect = [self fullWidthBoundingRectInTextView:_textView
                                               ofCharacterRange:_viewModel.selectedCharacterRange];
    _selectionRectangle.frame = CGRectIntegral(boundingRect);
  }
}

#pragma mark - UITextViewDelegate

- (void)textViewDidChange:(UITextView *)textView {
  if (!_selectionManager) {
    [self.delegate documentView:self didChangeText:self.text];
  }
}

#pragma mark - UIGestureRecognizerDelegate

- (BOOL)gestureRecognizerShouldBegin:(UIGestureRecognizer *)gestureRecognizer {
  NSParameterAssert(gestureRecognizer == _selectionRectPanRecognizer);
  CGPoint locationInTextView = [gestureRecognizer locationInView:_textView];
  if (CGRectIsEmpty(_selectionRectangle.frame)) {
    return NO;
  }
  if (locationInTextView.x >= CGRectGetMinX(_selectionInputBar.frame)) {
    return NO;
  }
  CGRect expandedSelectionBarFrame =
      CGRectInset(_selectionRectangle.frame, 0, -kSelectionRectVerticalPadding);
  return CGRectContainsPoint(expandedSelectionBarFrame, locationInTextView);
}

#pragma mark - PTASelectionDelegate

- (CGRect)insertionAreaRect  {
  NSAssert(!PTARangeEmptyOrNotFound(_viewModel.selectedCharacterRange),
           @"Calling %@ with empty selectedCharacterRange.",
           NSStringFromSelector(_cmd));
  NSAssert(_selectionTransform, @"Calling %@ with nil selectionTransform", NSStringFromSelector(_cmd));

  NSRange insertionRange = NSMakeRange(_selectionTransform.insertionLocation,
                                       _viewModel.selectedCharacterRange.length);
  return [self fullWidthBoundingRectInTextView:_textView ofCharacterRange:insertionRange];
}

- (NSRange)rangeForParagraphContainingPoint:(CGPoint)point outRect:(CGRect *)outRect {
  NSRange characterRange = [self characterRangeOfTextView:_textView paragraphContainingPoint:point];
  if (outRect != NULL) {
    *outRect = PTARangeEmptyOrNotFound(characterRange)
        ? CGRectNull
        : [self fullWidthBoundingRectInTextView:_textView ofCharacterRange:characterRange];
  }
  return characterRange;
}

#pragma mark - Private

- (void)updateSelectionTransform:(PTASelectionTransform *)selectionTransform {
  PTASelectionTransform *oldTransform = _selectionTransform;
  _selectionTransform = selectionTransform;
  CGAffineTransform translation;
  NSString *text;
  if (_selectionTransform) {
    CGPoint contentOffset = _textView.contentOffset;
    translation = CGAffineTransformMakeTranslation(_selectionTransform.selectionViewTranslation.x,
                                                   _selectionTransform.selectionViewTranslation.y);
    UITextPosition *locationBeginning = oldTransform
        ? [_textView positionFromPosition:_textView.beginningOfDocument offset:oldTransform.insertionLocation]
        : [_textView positionFromPosition:_textView.beginningOfDocument offset:_viewModel.selectedCharacterRange.location];
    UITextPosition *locationEnd = [_textView positionFromPosition:locationBeginning offset:_viewModel.selectedCharacterRange.length];
    UITextRange *textRange = [_textView textRangeFromPosition:locationBeginning toPosition:locationEnd];
    NSString *selectedText = [_textView textInRange:textRange];
    [_textView replaceRange:textRange withText:@""];

    UITextPosition *insertionLocation = [_textView positionFromPosition:_textView.beginningOfDocument
                                                                 offset:_selectionTransform.insertionLocation];
    UITextRange *insertionRange = [_textView textRangeFromPosition:insertionLocation toPosition:insertionLocation];
    [_textView replaceRange:insertionRange withText:selectedText];
    _textView.contentOffset = contentOffset;
  } else {
    translation = CGAffineTransformIdentity;
    text = _viewModel.text;
  }
  _selectionRectangle.transform = translation;
}

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
                                         paragraphContainingPoint:[panRecognizer locationInView:_textView]];
  [self.delegate documentView:self didDragToHighlightCharacterRange:selectedCharacterRange];
}

- (void)handleSelectionBarTap:(UITapGestureRecognizer *)tapRecognizer {
  if (tapRecognizer.state == UIGestureRecognizerStateRecognized) {
    [_textView resignFirstResponder];
    [self.delegate documentViewDidTapToCancelSelection:self];
  }
}

- (void)handleSelectionRectPan:(UIPanGestureRecognizer *)panRecognizer {
  switch (panRecognizer.state) {
    case UIGestureRecognizerStateBegan: {
      NSAssert(!PTARangeEmptyOrNotFound(_viewModel.selectedCharacterRange), @"Empty selectedCharacterRange");
      NSArray *paragraphsArray = [self paragraphsArrayForTextView:_textView
                                          excludingCharacterRange:_viewModel.selectedCharacterRange];
      _selectionManager = [[PTASelectionManager alloc] initWithSelectionRect:_selectionRectangle.frame
                                                              selectionRange:_viewModel.selectedCharacterRange
                                                                  paragraphs:paragraphsArray];
      PTASelectionTransform *initialTransform = [_selectionManager transformForTranslation:CGPointZero];
      [self updateSelectionTransform:initialTransform];
      break;
    }
    case UIGestureRecognizerStateChanged: {
      CGPoint translation = [panRecognizer translationInView:self];
      PTASelectionTransform *transform = [_selectionManager transformForTranslation:translation];
      [self updateSelectionTransform:transform];
      break;
    }
    case UIGestureRecognizerStateEnded:
    case UIGestureRecognizerStateCancelled: {
      NSString *text = _textView.text;
      [self updateSelectionTransform:nil];
      _selectionManager = nil;
      [self.delegate documentView:self didChangeText:text];
      break;
    }
    default: {
    
    }
  }
}

- (NSArray *)paragraphsArrayForTextView:(UITextView *)textView
                excludingCharacterRange:(NSRange)excludedRange {
  __block BOOL enumerationIncludedExcludedRange = NO;
  NSMutableArray *paragraphs = [NSMutableArray array];
  CGRect excludedRect = [self fullWidthBoundingRectInTextView:textView ofCharacterRange:excludedRange];
  CGFloat excludedRectHeight = CGRectGetHeight(excludedRect);
  [textView.text enumerateSubstringsInRange:NSMakeRange(0, textView.text.length)
                                    options:NSStringEnumerationByParagraphs
                                 usingBlock:^(NSString *substring, NSRange substringRange,
                                              NSRange enclosingRange,
                                              BOOL *stop) {
    if (NSEqualRanges(excludedRange, enclosingRange)) {
      NSAssert(!enumerationIncludedExcludedRange, @"Seen excluded range (%@) twice", NSStringFromRange(excludedRange));
      enumerationIncludedExcludedRange = YES;
      return;
    }
    NSString *text = [textView.text substringWithRange:enclosingRange];
    NSUInteger location = enumerationIncludedExcludedRange
        ? enclosingRange.location - excludedRange.length
        : enclosingRange.location;
    CGRect enclosingRect = [self fullWidthBoundingRectInTextView:textView ofCharacterRange:enclosingRange];
    if (enumerationIncludedExcludedRange) {
      enclosingRect = CGRectOffset(enclosingRect, 0, -excludedRectHeight);
    }
    CGFloat midY = CGRectGetMidY(enclosingRect);
    PTAParagraph *paragraph = [PTAParagraph paragraphWithText:text location:location midY:midY];
    [paragraphs addObject:paragraph];
  }];

  NSAssert(enumerationIncludedExcludedRange, @"Missed excluded range");
  return paragraphs;
}

- (NSRange)characterRangeOfTextView:(UITextView *)textView
           paragraphContainingPoint:(CGPoint)pointInTextView {
  NSParameterAssert(textView);
  CGRect boundingRect = CGRectMake(0, pointInTextView.y, CGRectGetWidth(textView.bounds), 1);
  NSRange glyphRange = [textView.layoutManager glyphRangeForBoundingRect:boundingRect
                                                         inTextContainer:textView.textContainer];
  NSRange characterRange = [textView.layoutManager characterRangeForGlyphRange:glyphRange
                                                               actualGlyphRange:NULL];
  if (PTARangeEmptyOrNotFound(characterRange)) {
    return characterRange;
  }
  return [_textView.text paragraphRangeForRange:characterRange];
}

- (CGRect)fullWidthBoundingRectInTextView:(UITextView *)textView
                         ofCharacterRange:(NSRange)characterRange {
  NSParameterAssert(textView);
  NSParameterAssert(!PTARangeEmptyOrNotFound(characterRange));
  NSRange glyphRange = [textView.layoutManager glyphRangeForCharacterRange:characterRange
                                                      actualCharacterRange:NULL];
  CGRect boundingRectInContainer = [textView.layoutManager boundingRectForGlyphRange:glyphRange
                                                                     inTextContainer:textView.textContainer];
  return CGRectMake(0, CGRectGetMinY(boundingRectInContainer) + textView.textContainerInset.top,
                    CGRectGetWidth(textView.bounds), CGRectGetHeight(boundingRectInContainer));
}

@end
