//
//  PTASelectionManager.m
//  Point
//
//  Created by Mikey Lintz on 11/20/14.
//  Copyright (c) 2014 Mikey Lintz. All rights reserved.
//

#import "PTASelectionManager.h"

typedef NS_ENUM(NSInteger, PTASelectionManagerDirection) {
  kPTASelectionManagerDirectionUnknown,
  kPTASelectionManagerDirectionVertical,
  kPTASelectionManagerDirectionHorizontal,
};

static NSComparator kParagraphComparator = ^NSComparisonResult(PTAParagraph *paragraph1,
                                                               PTAParagraph *paragraph2) {
  if (paragraph1.midY < paragraph2.midY) {
    return NSOrderedAscending;
  }
  if (paragraph1.midY > paragraph2.midY) {
    return NSOrderedDescending;
  }
  return NSOrderedSame;
};

@implementation PTASelectionTransform {
  NSString *_selectionText;
  NSString *_originalText;
  
  NSInteger _selectionLocation;
}

+ (instancetype)transformWithTranslation:(CGPoint)translation
                       selectionLocation:(NSUInteger)selectionLocation
                       insertionLocation:(NSUInteger)location
                           selectionText:(NSString *)selectionText
                           insertionText:(NSString *)insertionText
                            originalText:(NSString *)originalText {
  PTASelectionTransform *transform = [[self alloc] init];
  if (transform) {
    transform->_selectionViewTranslation = translation;
    transform->_insertionLocation = location;
    transform->_selectionLocation = (NSInteger)selectionLocation;
    transform->_selectionText = [selectionText copy];
    transform->_insertionText = [insertionText copy];
    transform->_originalText = [originalText copy];
  }
  return transform;
}

- (void)applyToTextView:(UITextView *)textView shouldApplyStyling:(BOOL)shouldApplyStyling {
  NSParameterAssert(textView);
  NSParameterAssert([textView.text isEqualToString:_originalText]);
  
  CGPoint contentOffset = textView.contentOffset;
  
  UITextPosition *selectionLocationBeginning = [textView positionFromPosition:textView.beginningOfDocument
                                                                       offset:_selectionLocation];
  UITextPosition *selectionLocationEnd = [textView positionFromPosition:selectionLocationBeginning
                                                                 offset:_selectionText.length];
  UITextRange *selectionRange = [textView textRangeFromPosition:selectionLocationBeginning
                                                     toPosition:selectionLocationEnd];
  [textView replaceRange:selectionRange withText:@""];
  
  NSAssert(self.insertionLocation <= textView.text.length, @"insertionLocation out of range: %d", (int)self.insertionLocation);
  
  UITextPosition *insertionLocation = [textView positionFromPosition:textView.beginningOfDocument
                                                              offset:self.insertionLocation];
  UITextRange *insertionRange = [textView textRangeFromPosition:insertionLocation
                                                     toPosition:insertionLocation];
  [textView replaceRange:insertionRange withText:_insertionText];
  if (shouldApplyStyling) {
    [textView.textStorage addAttribute:NSForegroundColorAttributeName
                                 value:[UIColor lightGrayColor]
                                 range:NSMakeRange(self.insertionLocation, _insertionText.length)];
    
  }
  textView.contentOffset = contentOffset;
}

- (void)unapplyToTextView:(UITextView *)textView {
  NSParameterAssert(textView);
  NSString *expectedText = [_originalText stringByReplacingCharactersInRange:NSMakeRange(_selectionLocation, _selectionText.length)
                                                                  withString:@""];
  expectedText = [expectedText stringByReplacingCharactersInRange:NSMakeRange(_insertionLocation, 0)
                                                       withString:_insertionText];
  NSParameterAssert([textView.text isEqualToString:expectedText]);
  
  CGPoint contentOffset = textView.contentOffset;
  
  UITextPosition *locationBeginning =
      [textView positionFromPosition:textView.beginningOfDocument offset:_insertionLocation];
  UITextPosition *locationEnd = [textView positionFromPosition:locationBeginning
                                                        offset:_insertionText.length];
  UITextRange *textRange = [textView textRangeFromPosition:locationBeginning toPosition:locationEnd];
  [textView replaceRange:textRange withText:@""];

  NSAssert(_selectionLocation <= textView.text.length, @"_selectionLocation out of range: %d", (int)_selectionLocation);

  UITextPosition *selectionLocation = [textView positionFromPosition:textView.beginningOfDocument
                                                              offset:_selectionLocation];
  UITextRange *selectionRange = [textView textRangeFromPosition:selectionLocation
                                                     toPosition:selectionLocation];
  [textView replaceRange:selectionRange withText:_selectionText];

  textView.contentOffset = contentOffset;
}

@end

@implementation PTAParagraph

+ (instancetype)paragraphWithText:(NSString *)text
                         location:(NSUInteger)location
                             midY:(CGFloat)midY {
  PTAParagraph *paragraph = [[self alloc] init];
  if (paragraph) {
    paragraph->_text = [text copy];
    paragraph->_textLocation = location;
    paragraph->_midY = midY;
  }
  return paragraph;
}

- (NSString *)description {
  return [NSString stringWithFormat:@"<%@: %p; midY = %f; location = %d; text = %@>",
          NSStringFromClass([self class]), self, _midY, (int)_textLocation, _text];
}

@end

@implementation PTASelectionManager {
  NSString *_selectionText;
  CGFloat _selectionTop;
  NSUInteger _selectionLocation;
  NSArray *_paragraphs;
  NSString *_originalText;

  PTASelectionManagerDirection _panDirection;
}

- (instancetype)init {
  [self doesNotRecognizeSelector:_cmd];
  return nil;
}

- (instancetype)initWithParagraphs:(NSArray *)paragraphs  // NSArray<PTAParagraph>
                     selectionText:(NSString *)selectionText
                      selectionTop:(CGFloat)selectionTop
                 selectionLocation:(NSUInteger)selectionLocation {
  self = [super init];
  if (self) {
    NSParameterAssert(paragraphs);
    NSParameterAssert(selectionText.length > 0);
    NSParameterAssert(selectionLocation != NSNotFound);
    _paragraphs = [paragraphs copy];
    _selectionText = [selectionText copy];
    _selectionTop = selectionTop;
    _selectionLocation = selectionLocation;
    
    _originalText = [[[self class] createOriginalTextWithParagraphsArray:_paragraphs
                                                           selectionText:_selectionText
                                                       selectionLocation:_selectionLocation] copy];
  }
  return self;
}

- (PTASelectionTransform *)transformForTranslation:(CGPoint)translation {
  if (_panDirection == kPTASelectionManagerDirectionUnknown) {
    if (translation.x == 0 && translation.y == 0) {
      // stay unknown
    } else if (ABS(translation.y) > ABS(translation.x)) {
      _panDirection = kPTASelectionManagerDirectionVertical;
    } else {
      _panDirection = kPTASelectionManagerDirectionHorizontal;
    }
  }

  CGPoint appliedTranslation;
  NSUInteger insertionLocation;
  NSString *insertionText;
  switch (_panDirection) {
    case kPTASelectionManagerDirectionUnknown:  // translation = {0, 0}
    case kPTASelectionManagerDirectionHorizontal: {
      appliedTranslation = CGPointMake(MIN(translation.x, 0), 0);
      insertionLocation = _selectionLocation;
      insertionText = _selectionText;
      break;
    }
    case kPTASelectionManagerDirectionVertical: {
      appliedTranslation = CGPointMake(0, translation.y);
      CGFloat selectionRectTop = _selectionTop + appliedTranslation.y;
      
      PTAParagraph *searchParagraph = [PTAParagraph paragraphWithText:nil location:0 midY:selectionRectTop];
      NSUInteger successorIndex = [_paragraphs indexOfObject:searchParagraph
                                               inSortedRange:NSMakeRange(0, _paragraphs.count)
                                                     options:NSBinarySearchingInsertionIndex
                                             usingComparator:kParagraphComparator];
      if (successorIndex < _paragraphs.count) {
        PTAParagraph *successorParagraph = _paragraphs[successorIndex];
        insertionLocation = successorParagraph.textLocation;
      } else {
        PTAParagraph *lastParagraph = [_paragraphs lastObject];
        insertionLocation = lastParagraph.textLocation + lastParagraph.text.length;
      }
      PTAParagraph *previousParagraph = successorIndex > 0 ? _paragraphs[successorIndex - 1] : nil;
      PTAParagraph *nextParagraph = successorIndex < _paragraphs.count ? _paragraphs[successorIndex] : nil;
      insertionText = [[self class] insertionTextWithSelectionText:_selectionText
                                                      previousLine:previousParagraph.text
                                                          nextLine:nextParagraph.text];
      break;
    }
  }

  return [PTASelectionTransform transformWithTranslation:appliedTranslation
                                       selectionLocation:_selectionLocation
                                       insertionLocation:insertionLocation
                                           selectionText:_selectionText
                                           insertionText:insertionText
                                            originalText:_originalText];
}

+ (NSString *)createOriginalTextWithParagraphsArray:(NSArray *)paragraphs  // PTAParagraph
                                      selectionText:(NSString *)selectionText
                                  selectionLocation:(NSUInteger)selectionLocation {
  NSMutableString *originalText = [NSMutableString string];
  BOOL didInsertSelectionText = NO;
  for (PTAParagraph *paragraph in paragraphs) {
    if (paragraph.textLocation == selectionLocation) {
      NSAssert(!didInsertSelectionText, @"Already inserted selection text");
      didInsertSelectionText = YES;
      [originalText appendString:selectionText];
    }
    [originalText appendString:paragraph.text];
  }
  if (selectionLocation == originalText.length) {
      NSAssert(!didInsertSelectionText, @"Already inserted selection text");
      didInsertSelectionText = YES;
      [originalText appendString:selectionText];
  }
  NSAssert(didInsertSelectionText, @"Didn't insert selection text");
  return originalText;
}

+ (NSString *)insertionTextWithSelectionText:(NSString *)selectionText 
                                previousLine:(NSString *)previousLine
                                    nextLine:(NSString *)nextLine {
  NSParameterAssert(selectionText);
  BOOL needsLeadingNewline = NO;
  BOOL needsTrailingNewline = NO;
  if (previousLine.length > 0 && ![previousLine pta_terminatesInNewline]) {
    needsLeadingNewline = YES;
  }
  if (nextLine.length > 0 && ![selectionText pta_terminatesInNewline]) {
    needsTrailingNewline = YES;
  }

  if (needsLeadingNewline && needsTrailingNewline) {
    return [NSString stringWithFormat:@"\n%@\n", selectionText];
  }
  if (needsLeadingNewline) {
    return [NSString stringWithFormat:@"\n%@", selectionText];
  }
  if (needsTrailingNewline) {
    return [NSString stringWithFormat:@"%@\n", selectionText];
  }
  return selectionText;
}

@end
