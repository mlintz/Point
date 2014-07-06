//
//  PTACategories.h
//  Point
//
//  Created by Mikey Lintz on 7/5/14.
//  Copyright (c) 2014 Mikey Lintz. All rights reserved.
//

extern CGPoint PTAInvertedPoint(CGPoint point);
extern CGPoint PTAAddPoints(CGPoint point1, CGPoint point2);

@interface UIGestureRecognizer (PTAUtil)
@property(nonatomic, readonly) BOOL isActive;
@end

@interface NSString (PTAUtil)
- (BOOL)containsNonWhitespaceCharacters;
@end

@interface UIView (PTAUtil)
- (UIImage *)snapshotCroppedToRect:(CGRect)rect;
@end