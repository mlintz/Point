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

// Immutable
@interface PTAParagraph : NSObject

@property(nonatomic, readonly) NSString *text;
@property(nonatomic, readonly) NSUInteger textLocation;
@property(nonatomic, readonly) CGFloat midY;

+ (instancetype)paragraphWithText:(NSString *)text location:(NSUInteger)location midY:(CGFloat)midY;

@end

@interface PTASelectionManager : NSObject

- (instancetype)initWithSelectionRect:(CGRect)selectionFrame
                       selectionRange:(NSRange)selectionRange
                           paragraphs:(NSArray *)paragraphs;  // NSArray<PTAParagraph>
- (PTASelectionTransform *)transformForTranslation:(CGPoint)translation;

@end
