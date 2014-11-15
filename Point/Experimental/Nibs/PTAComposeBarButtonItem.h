//
//  PTAComposeBarButtonItem.h
//  Point
//
//  Created by Mikey Lintz on 11/14/14.
//  Copyright (c) 2014 Mikey Lintz. All rights reserved.
//

@class PTAFilesystemManager;

@interface PTAComposeBarButtonItem : UIBarButtonItem

// controller is not retained
- (instancetype)initWithController:(UIViewController *)controller
                 filesystemManager:(PTAFilesystemManager *)manager;

@end
