//
//  PTAUtil.h
//  Point
//
//  Created by Mikey Lintz on 7/5/14.
//  Copyright (c) 2014 Mikey Lintz. All rights reserved.
//

extern const NSRange PTANullRange;  // length = 0, location = NSNotFound

extern CGPoint PTAPointInvert(CGPoint point);
extern CGPoint PTAPointAdd(CGPoint point1, CGPoint point2);
extern BOOL PTARangeEmptyOrNotFound(NSRange range);
extern NSUInteger PTARangeHash(NSRange range);
extern BOOL PTAEqualBOOL(BOOL bool1, BOOL bool2);

@interface UIGestureRecognizer (PTAUtil)

@property(nonatomic, readonly) BOOL pta_isActive;

- (void)cancel;

@end

@interface UIImage (PTAUtil)
+ (UIImage *)pta_imageWithFillColor:(UIColor *)color;
@end

@interface NSString (PTAUtil)
- (BOOL)containsNonWhitespaceCharacters;
- (NSString *)pta_stringBySquashingWhitespace:(NSString *)replacementString;
- (BOOL)pta_terminatesInNewline;
- (NSString *)pta_stringByTrimmingTerminatingCharactersInSet:(NSCharacterSet *)aSet;
@end

@interface UIView (PTAUtil)
- (UIImage *)snapshotCroppedToRect:(CGRect)rect;
@end

@interface UIViewController (PTAUtil)
- (BOOL)pta_isActive;
@end
