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
@property(nonatomic, readonly) NSUInteger insertionLocation;  // Relative to string with selected characters removed
@property(nonatomic, readonly) NSString *insertionText;

- (void)applyToTextView:(UITextView *)textView shouldApplyStyling:(BOOL)shouldApplyStyling;
- (void)unapplyToTextView:(UITextView *)textView;

@end

// Immutable
@interface PTAParagraph : NSObject

@property(nonatomic, readonly) NSString *text;
@property(nonatomic, readonly) NSUInteger textLocation;
@property(nonatomic, readonly) CGFloat midY;

+ (instancetype)paragraphWithText:(NSString *)text location:(NSUInteger)location midY:(CGFloat)midY;

@end

@interface PTASelectionManager : NSObject

- (instancetype)initWithParagraphs:(NSArray *)paragraphs  // NSArray<PTAParagraph>
                     selectionText:(NSString *)selectionText
                      selectionTop:(CGFloat)selectionTop
                 selectionLocation:(NSUInteger)selectionLocation;
- (PTASelectionTransform *)transformForTranslation:(CGPoint)translation;

@end
