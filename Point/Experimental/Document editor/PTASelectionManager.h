//
//  PTASelectionManager.h
//  Point
//
//  Created by Mikey Lintz on 11/20/14.
//  Copyright (c) 2014 Mikey Lintz. All rights reserved.
//

@class PTASelectionManager;

// Immutable
@interface PTASelectionTransform : NSObject

@property(nonatomic, readonly) CGPoint selectionViewTranslation;
@property(nonatomic, readonly) NSUInteger insertionLocation;  // Relative to string selected characters removed

@end

@protocol PTASelectionDelegate <NSObject>

- (CGRect)insertionAreaRect;

// outRect may be NULL
- (NSRange)rangeForParagraphContainingPoint:(CGPoint)point
                                    outRect:(CGRect *)outRect;

@end

@interface PTASelectionManager : NSObject

@property(nonatomic, readonly) PTASelectionTransform *transform;

- (instancetype)initWithSelectionRect:(CGRect)selectionFrame
                       selectionRange:(NSRange)selectionRange
                             delegate:(id<PTASelectionDelegate>)delegate;
- (PTASelectionTransform *)updateWithTranslation:(CGPoint)translation;

@end
