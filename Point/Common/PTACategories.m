//
//  PTACategories.m
//  Point
//
//  Created by Mikey Lintz on 7/5/14.
//  Copyright (c) 2014 Mikey Lintz. All rights reserved.
//

#import "PTACategories.h"

CGPoint PTAPointInvert(CGPoint point) {
  return CGPointMake(-1 * point.x, -1 * point.y);
}

CGPoint PTAPointAdd(CGPoint point1, CGPoint point2) {
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

@implementation UIViewController (PTAUtil)

- (BOOL)pta_isActive {
  return self.isViewLoaded && (self.view.window != nil);
}

@end
