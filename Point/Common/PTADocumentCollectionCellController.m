//
//  PTADocumentCollectionCellController.m
//  Point
//
//  Created by Mikey Lintz on 12/12/14.
//  Copyright (c) 2014 Mikey Lintz. All rights reserved.
//

#import "PTADocumentCollectionCellController.h"

@interface PTADocumentCollectionCellController ()<PTAFileObserver>
@end

@implementation PTADocumentCollectionCellController {
  PTAFilesystemManager *_manager;
  UITableViewCell *_cell;
  NSDateFormatter *_dateFormatter;
}

- (instancetype)init {
  [self doesNotRecognizeSelector:_cmd];
  return nil;
}

- (instancetype)initWithFilesystemManager:(PTAFilesystemManager *)manager
                            dateFormatter:(NSDateFormatter *)formatter {
  NSParameterAssert(manager);
  if (self) {
    _manager = manager;
    _dateFormatter = formatter;
  }
  return self;
}

- (void)setCell:(UITableViewCell *)cell withFilePath:(DBPath *)path {
  [_manager removeFileObserver:self];
  _cell = cell;
  [_manager addFileObserver:self forPath:path];
  PTAFile *file = [_manager fileForPath:path];
  [self.class updateCell:_cell withFile:file dateFormatter:_dateFormatter];
}

- (void)clearCell {
  _cell = nil;
  [_manager removeFileObserver:self];
}

#pragma mark PTAFileObserver

- (void)fileDidChange:(PTAFile *)file {
  [self.class updateCell:_cell withFile:file dateFormatter:_dateFormatter];
}

#pragma mark Private

+ (void)updateCell:(UITableViewCell *)cell
          withFile:(PTAFile *)file
     dateFormatter:(NSDateFormatter *)formatter {
  cell.textLabel.text = [file nameWithEmojiStatus];
  cell.detailTextLabel.text = [formatter stringFromDate:file.info.modifiedTime];
}

@end
