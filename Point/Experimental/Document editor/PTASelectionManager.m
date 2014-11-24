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
  PTASelectionManagerDirection _panDirection;
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
    _panDirection = kPTASelectionManagerDirectionUnknown;
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
  switch (_panDirection) {
    case kPTASelectionManagerDirectionUnknown:  // translation = {0, 0}
    case kPTASelectionManagerDirectionHorizontal: {
      appliedTranslation = CGPointMake(MIN(translation.x, 0), 0);
      insertionLocation = _selectionRange.location;
      break;
    }
    case kPTASelectionManagerDirectionVertical: {
      appliedTranslation = CGPointMake(0, translation.y);
      CGFloat selectionRectTop = CGRectGetMinY(_selectionFrame) + appliedTranslation.y;
      
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
      break;
    }
  }

  return [PTASelectionTransform transformWithTranslation:appliedTranslation
                                       insertionLocation:insertionLocation];
}

@end
