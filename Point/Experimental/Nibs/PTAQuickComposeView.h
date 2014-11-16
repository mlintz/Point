//
//  PTAQuickComposeView.h
//  Point
//
//  Created by Mikey Lintz on 11/15/14.
//  Copyright (c) 2014 Mikey Lintz. All rights reserved.
//

@class PTAQuickComposeView;

@protocol PTAQuickComposeDelegate <NSObject>

- (void)quickComposeViewdidTapAddToInbox:(PTAQuickComposeView *)view withText:(NSString *)text;
- (void)quickComposeViewdidTapAddToOther:(PTAQuickComposeView *)view withText:(NSString *)text;

@end

@interface PTAQuickComposeView : UIView
@property(nonatomic, weak) id<PTAQuickComposeDelegate> delegate;
@end
