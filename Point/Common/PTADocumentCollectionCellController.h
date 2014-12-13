//
//  PTADocumentCollectionCellController.h
//  Point
//
//  Created by Mikey Lintz on 12/12/14.
//  Copyright (c) 2014 Mikey Lintz. All rights reserved.
//

@interface PTADocumentCollectionCellController : NSObject

- (instancetype)initWithFilesystemManager:(PTAFilesystemManager *)manager
                            dateFormatter:(NSDateFormatter *)formatter;
- (void)setCell:(UITableViewCell *)cell withFilePath:(DBPath *)path;
- (void)clearCell;

@end
