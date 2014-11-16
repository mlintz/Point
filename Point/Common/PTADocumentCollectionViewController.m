//Next:
// 1) show spinner while waiting for filesystem to sync
// 2) on filesystem changed, grab new fileinfos, show or hide spinner, and reset tableview
// 3) implement datasource methods
//  - spinner in upper right if sync in progress?
//  - icon in file cell if sync in progress?
//  - add header icon showing download/upload state

//
//  PTADocumentCollectionViewController.m
//  Point
//
//  Created by Mikey Lintz on 8/31/14.
//  Copyright (c) 2014 Mikey Lintz. All rights reserved.
//

#import "PTADocumentCollectionViewController.h"

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
}

- (instancetype)init {
  [self doesNotRecognizeSelector:_cmd];
  return nil;
}

- (instancetype)initWithFilesystemManager:(PTAFilesystemManager *)filesystemManager {
  NSParameterAssert(filesystemManager);
  self = [super init];
  if (self) {
    _dateFormatter = [[NSDateFormatter alloc] init];
    [_dateFormatter setDateStyle:NSDateFormatterMediumStyle];
    [_dateFormatter setTimeStyle:NSDateFormatterShortStyle];

    _filesystemManager = filesystemManager;
  
    [filesystemManager addDirectoryObserver:self];
    _directory = _filesystemManager.directory;
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

//- (void)viewDidAppear:(BOOL)animated {
//  [super viewDidAppear:animated];
//  DBAccountManager *accountManager = [DBAccountManager sharedManager];
//  if (!accountManager.linkedAccount) {
//    [accountManager linkFromController:self];
//  }
//  DBAccount *account = [[DBAccountManager sharedManager] linkedAccount];
//  if (!DBFilesystem.sharedFilesystem) {
//    DBFilesystem *filesystem = [[DBFilesystem alloc] initWithAccount:account];
//    [DBFilesystem setSharedFilesystem:filesystem];
//    __weak id weakSelf = self;
//    [DBFilesystem.sharedFilesystem addObserver:self block:^{
//      [weakSelf updateView];
//    }];
//    [DBFilesystem.sharedFilesystem addObserver:self forPathAndChildren:DBPath.root block:^{
//      [weakSelf updateView];
//    }];
//  }
//  [self updateView];
//}

#pragma mark - UITableViewDataSource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
  if (section == 0) {
    return _directory.didCompleteFirstSync ? _directory.fileInfos.count : 0;
  }
  return 0;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
  PTATableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:reuseIdentifier];
  PTAFileInfo *info = _directory.fileInfos[indexPath.row];
  cell.textLabel.text = info.path.name;
  cell.detailTextLabel.text = [_dateFormatter stringFromDate:info.modifiedTime];
  return cell;
}

#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {

  PTAFileInfo *fileInfo = _directory.fileInfos[indexPath.row];
  [self.delegate documentCollectionController:self didSelectPath:fileInfo.path];
//  PTADocumentViewController *vc = [[PTADocumentViewController alloc] initWithManager:_filesystemManager path:fileInfo.path];
//  [self.navigationController pushViewController:vc animated:YES];

//  DBFileInfo *fileInfo = _fileInfos[indexPath.row];
//  NSError *error;
//  DBFile *file = [DBFilesystem.sharedFilesystem openFile:fileInfo.path error:&error];
//  NSAssert(!error, error.localizedDescription);
//
//  PTADocumentViewController *vc = [[PTADocumentViewController alloc] init];
//  vc.file = file;
//
//  [self.navigationController pushViewController:vc animated:YES];
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

//- (void)updateView {
//  NSError *error;
//  if (!DBFilesystem.sharedFilesystem.completedFirstSync) {
//    _spinnerView.hidden = NO;
//    _fileInfos = nil;
//  } else {
//    _spinnerView.hidden = YES;
//    _fileInfos = [[DBFilesystem.sharedFilesystem listFolder:[DBPath root] error:&error] pta_filteredArrayWithPathExtension:@"txt"];
//    NSAssert(!error, error.localizedDescription);
//  }
//  [_tableView reloadData];
//}

@end
