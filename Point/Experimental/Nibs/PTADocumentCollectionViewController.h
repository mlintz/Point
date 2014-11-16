//
//  PTADocumentCollectionViewController.h
//  Point
//
//  Created by Mikey Lintz on 8/31/14.
//  Copyright (c) 2014 Mikey Lintz. All rights reserved.
//

@class PTAFilesystemManager;
@class PTADocumentCollectionViewController;

@protocol PTADocumentCollectionDelegate <NSObject>

- (void)documentCollectionController:(PTADocumentCollectionViewController *)controller
                       didSelectPath:(DBPath *)path;

@end

@interface PTADocumentCollectionViewController : UIViewController

@property(nonatomic, weak) id<PTADocumentCollectionDelegate> delegate;

- (instancetype)initWithFilesystemManager:(PTAFilesystemManager *)filesystemManager;

@end
