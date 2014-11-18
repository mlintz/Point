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

@interface UIGestureRecognizer (PTAUtil)
@property(nonatomic, readonly) BOOL isActive;
@end

@interface NSString (PTAUtil)
- (BOOL)containsNonWhitespaceCharacters;
- (NSString *)pta_stringBySquashingWhitespace:(NSString *)replacementString;
@end

@interface UIView (PTAUtil)
- (UIImage *)snapshotCroppedToRect:(CGRect)rect;
@end

@interface UIViewController (PTAUtil)
- (BOOL)pta_isActive;
@end
