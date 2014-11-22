//
//  PTASelectionManager.m
//  Point
//
//  Created by Mikey Lintz on 11/20/14.
//  Copyright (c) 2014 Mikey Lintz. All rights reserved.
//

#import "PTASelectionManager.h"

@implementation PTASelectionTransform

- (instancetype)init {
  [self doesNotRecognizeSelector:_cmd];
  return nil;
}

- (instancetype)initWithTranslation:(CGPoint)translation
                  insertionLocation:(NSUInteger)location {
  self = [super init];
  if (self) {
    _selectionViewTranslation = translation;
    _insertionLocation = location;
  }
  return self;
}

@end

@implementation PTASelectionManager {
  id<PTASelectionDelegate> _delegate;
  CGRect _selectionFrame;
  NSRange _selectionRange;
}

- (instancetype)init {
  [self doesNotRecognizeSelector:_cmd];
  return nil;
}

- (instancetype)initWithSelectionRect:(CGRect)selectionFrame
                       selectionRange:(NSRange)selectionRange
                             delegate:(id<PTASelectionDelegate>)delegate {
  self = [super init];
  if (self) {
    NSParameterAssert(delegate);
    NSParameterAssert(!CGRectIsEmpty(selectionFrame));
    NSParameterAssert(!PTARangeEmptyOrNotFound(selectionRange));
    _delegate = delegate;
    _selectionFrame = selectionFrame;
    _selectionRange = selectionRange;

    CGPoint initialCenter = CGPointMake(CGRectGetMidX(selectionFrame), CGRectGetMidY(selectionFrame));
    NSRange initialRange = [_delegate rangeForParagraphContainingPoint:initialCenter
                                                               outRect:NULL];

    _transform = [[PTASelectionTransform alloc] initWithTranslation:CGPointZero
                                                  insertionLocation:initialRange.location];
  }
  return self;
}

- (PTASelectionTransform *)updateWithTranslation:(CGPoint)translation {
  CGPoint verticalTranslation = CGPointMake(0, translation.y);
  CGFloat selectionRectTop = CGRectGetMinY(_selectionFrame) + verticalTranslation.y;
  BOOL isSelectionBelowInsertionPoint = selectionRectTop > CGRectGetMinY([_delegate insertionAreaRect]);
  if (isSelectionBelowInsertionPoint) {
    selectionRectTop = selectionRectTop + CGRectGetHeight(_selectionFrame);
  }
  CGRect intersectingRect;
  NSRange insertionRange = [_delegate rangeForParagraphContainingPoint:CGPointMake(0, selectionRectTop)
                                                               outRect:&intersectingRect];
  if (CGRectIsEmpty(intersectingRect)) {
    return _transform;
  }

  NSUInteger insertionLocation = selectionRectTop < CGRectGetMidY(intersectingRect)
      ? insertionRange.location
      : NSMaxRange(insertionRange);
  
  if (isSelectionBelowInsertionPoint) {
    insertionLocation = insertionLocation - _selectionRange.length;
  }

  _transform = [[PTASelectionTransform alloc] initWithTranslation:verticalTranslation
                                                insertionLocation:insertionLocation];
  return _transform;
}

@end
