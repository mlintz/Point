//
//  PTAUtil.m
//  Point
//
//  Created by Mikey Lintz on 7/5/14.
//  Copyright (c) 2014 Mikey Lintz. All rights reserved.
//

const NSRange PTANullRange = { .length = 0, .location = NSNotFound };

CGPoint PTAPointInvert(CGPoint point) {
  return CGPointMake(-1 * point.x, -1 * point.y);
}

CGPoint PTAPointAdd(CGPoint point1, CGPoint point2) {
  return CGPointMake(point1.x + point2.x, point1.y + point2.y);
}

BOOL PTARangeEmptyOrNotFound(NSRange range) {
  return range.location == NSNotFound || range.length == 0;
}

NSUInteger PTARangeHash(NSRange range) {
  return range.location ^ range.length;
}

@implementation UIGestureRecognizer (PTAUtil)

- (BOOL)isActive {
  return self.state == UIGestureRecognizerStateBegan ||
      self.state == UIGestureRecognizerStateChanged;
}

@end

@implementation UIImage (PTAUtil)

+ (UIImage *)pta_imageWithFillColor:(UIColor *)color {
  NSParameterAssert(color);
  CGFloat width = 1;
  CGFloat height = 1;

  UIGraphicsBeginImageContextWithOptions(CGSizeMake(width, height), YES, 0);
  [color setFill];
  UIRectFill(CGRectMake(0, 0, width, height));
  UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
  UIGraphicsEndImageContext();

  return image;
}

@end

@implementation NSString (PTAUtil)

- (BOOL)containsNonWhitespaceCharacters {
  return [[self stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]] length];
}

- (NSString *)pta_stringBySquashingWhitespace:(NSString *)replacementString {
  NSArray *components =
      [self componentsSeparatedByCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
  components = [components filteredArrayUsingPredicate:[NSPredicate predicateWithBlock:^BOOL(NSString *component,
                                                                                             NSDictionary *bindings) {
    return [component length] > 0;
  }]];
  return [components componentsJoinedByString:replacementString];
}

- (BOOL)pta_terminatesInNewline {
  if (!self.length) {
    return NO;
  }
  unichar lastChar = [self characterAtIndex:self.length - 1];
  return [[NSCharacterSet newlineCharacterSet] characterIsMember:lastChar];
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
