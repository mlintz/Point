//
//  PTACategories.m
//  Point
//
//  Created by Mikey Lintz on 7/5/14.
//  Copyright (c) 2014 Mikey Lintz. All rights reserved.
//

#import "PTACategories.h"

CGPoint PTAInvertedPoint(CGPoint point) {
  return CGPointMake(-1 * point.x, -1 * point.y);
}

extern CGPoint PTAAddPoints(CGPoint point1, CGPoint point2) {
  return CGPointMake(point1.x + point2.x, point1.y + point2.y);
}

@implementation UIGestureRecognizer (PTAUtil)

- (BOOL)isActive {
  return self.state == UIGestureRecognizerStateBegan ||
      self.state == UIGestureRecognizerStateChanged;
}

@end

@implementation NSString (PTAUtil)

- (BOOL)containsNonWhitespaceCharacters {
  return [[self stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]] length];
}

@end

@implementation UIView (PTAUtil)

- (UIImage *)snapshotCroppedToRect:(CGRect)rect {
  UIGraphicsBeginImageContextWithOptions(rect.size, NO, 0.f);
  CGContextRef context = UIGraphicsGetCurrentContext();

  CGContextTranslateCTM(context, -1 * CGRectGetMinX(rect), -1 * CGRectGetMinY(rect));
  [[self layer] renderInContext:context];
  UIImage *snapshot = UIGraphicsGetImageFromCurrentImageContext();
  UIGraphicsEndImageContext();
  return snapshot;
}

@end
