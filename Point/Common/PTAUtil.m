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

BOOL PTAEqualBOOL(BOOL bool1, BOOL bool2) {
  return (bool1 && bool2) || (!bool1 && !bool2);
}

@implementation UIGestureRecognizer (PTAUtil)

- (BOOL)pta_isActive {
  return self.state == UIGestureRecognizerStateBegan ||
      self.state == UIGestureRecognizerStateChanged;
}

- (void)cancel {
  self.enabled = NO;
  self.enabled = YES;
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

- (NSString *)pta_stringByTrimmingTerminatingCharactersInSet:(NSCharacterSet *)aSet {
  NSParameterAssert(aSet);
  if (self.length == 0) {
    return self;
  }
  NSUInteger maxIndex = self.length - 1;
  while (maxIndex > 0) {
    unichar c = [self characterAtIndex:maxIndex];
    if (![aSet characterIsMember:c]) {
      return [self substringToIndex:maxIndex];
    }
    maxIndex--;
  }
  return @"";
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
