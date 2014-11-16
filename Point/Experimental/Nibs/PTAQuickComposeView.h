//
//  PTAQuickComposeView.h
//  Point
//
//  Created by Mikey Lintz on 11/15/14.
//  Copyright (c) 2014 Mikey Lintz. All rights reserved.
//

@class PTAQuickComposeView;

@protocol PTAQuickComposeDelegate <NSObject>

- (void)quickComposeViewDidTapAddToInbox:(PTAQuickComposeView *)view withText:(NSString *)text;
- (void)quickComposeViewDidTapAddToOther:(PTAQuickComposeView *)view withText:(NSString *)text;

@end

@interface PTAQuickComposeView : UIView

@property(nonatomic, weak) id<PTAQuickComposeDelegate> delegate;
@property(nonatomic, readonly) NSString *text;

@end
