//
//  PTADocumentViewController.h
//  Point
//
//  Created by Mikey Lintz on 9/1/14.
//  Copyright (c) 2014 Mikey Lintz. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface PTADocumentViewController : UIViewController<UITextViewDelegate>
@property(nonatomic, copy) DBFile *file;
@end
