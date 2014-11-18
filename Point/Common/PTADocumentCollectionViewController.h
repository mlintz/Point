//
//  PTADocumentCollectionViewController.h
//  Point
//
//  Created by Mikey Lintz on 8/31/14.
//  Copyright (c) 2014 Mikey Lintz. All rights reserved.
//

@class PTAFilesystemManager;
@class PTADocumentCollectionViewController;

typedef void (^PTADocumentCollectionSelection)(PTADocumentCollectionViewController *collectionController, DBPath *path);

@interface PTADocumentCollectionViewController : UIViewController

- (instancetype)initWithFilesystemManager:(PTAFilesystemManager *)filesystemManager
                                 callback:(PTADocumentCollectionSelection)callback;

@end
