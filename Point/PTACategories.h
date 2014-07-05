//
//  PTACategories.h
//  Point
//
//  Created by Mikey Lintz on 7/5/14.
//  Copyright (c) 2014 Mikey Lintz. All rights reserved.
//

@interface UIGestureRecognizer (PTAUtil)
@property(nonatomic, readonly) BOOL isActive;
@end

@interface NSString (PTAUtil)
- (BOOL)containsNonWhitespaceCharacters;
@end
