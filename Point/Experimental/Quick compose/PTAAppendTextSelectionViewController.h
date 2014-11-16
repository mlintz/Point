//
//  PTAAppendTextSelectionViewController.h
//  Point
//
//  Created by Mikey Lintz on 11/15/14.
//  Copyright (c) 2014 Mikey Lintz. All rights reserved.
//

@class PTAAppendTextSelectionViewController;

@protocol PTAAppendTextSelectionDelegate <NSObject>
- (void)appendTextControllerDidComplete:(PTAAppendTextSelectionViewController *)controller;
@end

@interface PTAAppendTextSelectionViewController : UIViewController

@property(nonatomic, weak) id<PTAAppendTextSelectionDelegate> delegate;

- (instancetype)initWithFilesystemManager:(PTAFilesystemManager *)manager
                               appendText:(NSString *)text;

@end
