//
//  PTASelectionManager.m
//  Point
//
//  Created by Mikey Lintz on 11/20/14.
//  Copyright (c) 2014 Mikey Lintz. All rights reserved.
//

#import "PTASelectionManager.h"

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

@implementation PTASelectionTransform

+ (instancetype)transformWithTranslation:(CGPoint)translation
                       insertionLocation:(NSUInteger)location {
  PTASelectionTransform *transform = [[self alloc] init];
  if (transform) {
    transform->_selectionViewTranslation = translation;
    transform->_insertionLocation = location;
  }
  return transform;
}

@end

@implementation PTAParagraph

+ (instancetype)paragraphWithText:(NSString *)text location:(NSUInteger)location midY:(CGFloat)midY {
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
  CGRect _selectionFrame;
  NSRange _selectionRange;
  NSArray *_paragraphs;
}

- (instancetype)init {
  [self doesNotRecognizeSelector:_cmd];
  return nil;
}

- (instancetype)initWithSelectionRect:(CGRect)selectionFrame
                       selectionRange:(NSRange)selectionRange
                           paragraphs:(NSArray *)paragraphs {
  self = [super init];
  if (self) {
    NSParameterAssert(paragraphs);
    NSParameterAssert(!CGRectIsEmpty(selectionFrame));
    NSParameterAssert(!PTARangeEmptyOrNotFound(selectionRange));
    _selectionFrame = selectionFrame;
    _selectionRange = selectionRange;
    _paragraphs = [paragraphs copy];
  }
  return self;
}

- (PTASelectionTransform *)transformForTranslation:(CGPoint)translation {
  CGPoint verticalTranslation = CGPointMake(0, translation.y);
  CGFloat selectionRectTop = CGRectGetMinY(_selectionFrame) + verticalTranslation.y;

  PTAParagraph *searchParagraph = [PTAParagraph paragraphWithText:nil location:0 midY:selectionRectTop];
  NSUInteger successorIndex = [_paragraphs indexOfObject:searchParagraph
                                                      inSortedRange:NSMakeRange(0, _paragraphs.count)
                                                            options:NSBinarySearchingInsertionIndex
                                                    usingComparator:kParagraphComparator];
  NSUInteger insertionLocation;
  if (successorIndex < _paragraphs.count) {
    PTAParagraph *successorParagraph = _paragraphs[successorIndex];
    insertionLocation = successorParagraph.textLocation;
  } else {
    PTAParagraph *lastParagraph = [_paragraphs lastObject];
    insertionLocation = lastParagraph.textLocation + lastParagraph.text.length;
  }

  return [PTASelectionTransform transformWithTranslation:verticalTranslation
                                       insertionLocation:insertionLocation];
}

@end
