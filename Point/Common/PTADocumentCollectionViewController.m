//
//  PTADocumentCollectionViewController.m
//  Point
//
//  Created by Mikey Lintz on 8/31/14.
//  Copyright (c) 2014 Mikey Lintz. All rights reserved.
//

#import "PTADocumentCollectionViewController.h"

#import "PTADocumentCollectionCellController.h"

static NSString *reuseIdentifier = @"PTACollectionViewReuseIdentifier";

@interface NSArray (DocumentCollection)
- (NSArray *)pta_filteredArrayWithPathExtension:(NSString *)pathExtension;
@end

@implementation NSArray (DocumentCollection)

- (NSArray *)pta_filteredArrayWithPathExtension:(NSString *)pathExtension {
  return [self filteredArrayUsingPredicate:[NSPredicate predicateWithBlock:^BOOL(DBFileInfo *info, NSDictionary *_) {
    return [info.path.name.pathExtension isEqualToString:pathExtension];
  }]];
}

@end

@interface PTATableViewCell : UITableViewCell
@end

@implementation PTATableViewCell

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
  return [super initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:reuseIdentifier];
}

@end

@interface PTADocumentCollectionViewController ()<UITableViewDelegate, UITableViewDataSource, PTADirectoryObserver>
@end

@implementation PTADocumentCollectionViewController {
  UITableView *_tableView;
  UIActivityIndicatorView *_spinnerView;
  NSDateFormatter *_dateFormatter;

  PTAFilesystemManager *_filesystemManager;
  PTADirectory *_directory;
  PTADocumentCollectionSelection _selectionCallback;

  NSMutableDictionary *_indexPathControllerMap;  // NSIndexPath / PTADocumentCollectionCellController
  NSMutableArray *_controllerPool;  // PTADocumentCollectionCellController
}

- (instancetype)init {
  [self doesNotRecognizeSelector:_cmd];
  return nil;
}

- (instancetype)initWithFilesystemManager:(PTAFilesystemManager *)filesystemManager
                                 callback:(PTADocumentCollectionSelection)callback {
  NSParameterAssert(filesystemManager);
  self = [super init];
  if (self) {
    _dateFormatter = [[NSDateFormatter alloc] init];
    [_dateFormatter setDateStyle:NSDateFormatterMediumStyle];
    [_dateFormatter setTimeStyle:NSDateFormatterShortStyle];

    _filesystemManager = filesystemManager;
  
    [filesystemManager addDirectoryObserver:self];
    _directory = _filesystemManager.directory;

    _selectionCallback = [callback copy];

    _controllerPool = [NSMutableArray array];
    _indexPathControllerMap = [NSMutableDictionary dictionary];
  }
  return self;
}

- (void)loadView {
  self.view = [[UIView alloc] init];

  _tableView = [[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStylePlain];
  _tableView.dataSource = self;
  _tableView.delegate = self;
  [_tableView registerClass:[PTATableViewCell class] forCellReuseIdentifier:reuseIdentifier];
  [self.view addSubview:_tableView];
 
  _spinnerView = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
  _spinnerView.hidesWhenStopped = YES;
  [_spinnerView startAnimating];
  [self.view addSubview:_spinnerView];

  [self updateSpinnerVisibility];
}

- (void)viewWillLayoutSubviews {
  [super viewWillLayoutSubviews];

  _tableView.frame = self.view.bounds;

  [_spinnerView sizeToFit];
  _spinnerView.center = _tableView.center;
}

- (void)viewWillAppear:(BOOL)animated {
  [super viewWillAppear:animated];
  NSIndexPath *path = _tableView.indexPathForSelectedRow;
  [_tableView deselectRowAtIndexPath:path animated:NO];
}

#pragma mark - UITableViewDataSource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
  if (section == 0) {
    return _directory.didCompleteFirstSync ? _directory.fileInfos.count : 0;
  }
  return 0;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
  return [tableView dequeueReusableCellWithIdentifier:reuseIdentifier];
}

#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
  PTAFileInfo *fileInfo = _directory.fileInfos[indexPath.row];
  if (_selectionCallback) {
    _selectionCallback(self, fileInfo.path);
  }
}

- (void)tableView:(UITableView *)tableView
      willDisplayCell:(UITableViewCell *)cell
    forRowAtIndexPath:(NSIndexPath *)indexPath {
  PTADocumentCollectionCellController *cellController = [_controllerPool lastObject];
  [_controllerPool removeLastObject];
  if (!cellController) {
    cellController =
        [[PTADocumentCollectionCellController alloc] initWithFilesystemManager:_filesystemManager
                                                                 dateFormatter:_dateFormatter];
  }
  _indexPathControllerMap[indexPath] = cellController;
  PTAFileInfo *info = _directory.fileInfos[indexPath.row];
  [cellController setCell:cell withFilePath:info.path];
}

- (void)tableView:(UITableView *)tableView
    didEndDisplayingCell:(UITableViewCell *)cell
       forRowAtIndexPath:(NSIndexPath *)indexPath {
  PTADocumentCollectionCellController *cellController = _indexPathControllerMap[indexPath];
  NSAssert(cellController, @"No cellController for indexPath: %@. Map: %@",
           indexPath, _indexPathControllerMap);
  [cellController clearCell];
  [_indexPathControllerMap removeObjectForKey:indexPath];
  [_controllerPool addObject:cellController];
}

#pragma mark - PTADirectoryObserver

- (void)directoryDidChange:(PTADirectory *)directory {
  _directory = directory;
  [self updateSpinnerVisibility];
  [_tableView reloadData];
}

#pragma mark - Private

- (void)updateSpinnerVisibility {
  if (_directory.didCompleteFirstSync) {
    [_spinnerView stopAnimating];
  } else {
    [_spinnerView startAnimating];
  }
}

@end
