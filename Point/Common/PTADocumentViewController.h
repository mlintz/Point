//
//  PTADocumentViewController.h
//  Point
//
//  Created by Mikey Lintz on 9/1/14.
//  Copyright (c) 2014 Mikey Lintz. All rights reserved.
//

@class PTAFilesystemManager;

@interface PTADocumentViewController : UIViewController

- (instancetype)initWithManager:(PTAFilesystemManager *)manager path:(DBPath *)path;

@end
