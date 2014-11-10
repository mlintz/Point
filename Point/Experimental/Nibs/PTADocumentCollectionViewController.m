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

#import "PTADocumentViewController.h"

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

@implementation PTADocumentCollectionViewController {
  UITableView *_tableView;
  UIActivityIndicatorView *_spinnerView;
  NSDateFormatter *_dateFormatter;
  NSArray *_dummyStrings;
  NSArray *_fileInfos;
}

- (id)init {
  self = [super init];
  if (self) {
    _dummyStrings = @[@"alpha", @"bravo", @"charlie", @"dogtrot", @"echo"];
    self.navigationItem.title = @"All Documents";
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd
                                                                                           target:self
                                                                                           action:@selector(handleAddTapped:)];
  
    _dateFormatter = [[NSDateFormatter alloc] init];
    [_dateFormatter setDateStyle:NSDateFormatterMediumStyle];
    [_dateFormatter setTimeStyle:NSDateFormatterShortStyle];
  }
  return self;
}

- (void)loadView {
  _tableView = [[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStylePlain];
  _tableView.dataSource = self;
  _tableView.delegate = self;
  [_tableView registerClass:[PTATableViewCell class] forCellReuseIdentifier:reuseIdentifier];
 
  _spinnerView = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
  [_spinnerView startAnimating];
  [_tableView addSubview:_spinnerView];
  
  self.view = _tableView;
}

- (void)viewWillLayoutSubviews {
  [super viewWillLayoutSubviews];
  [_spinnerView sizeToFit];
  _spinnerView.center = _tableView.center;
}

- (void)viewWillAppear:(BOOL)animated {
  [super viewWillAppear:animated];
  NSIndexPath *path = _tableView.indexPathForSelectedRow;
  [_tableView deselectRowAtIndexPath:path animated:NO];
}

- (void)viewDidAppear:(BOOL)animated {
  [super viewDidAppear:animated];
  DBAccountManager *accountManager = [DBAccountManager sharedManager];
  if (!accountManager.linkedAccount) {
    [accountManager linkFromController:self];
  }
  DBAccount *account = [[DBAccountManager sharedManager] linkedAccount];
  if (!DBFilesystem.sharedFilesystem) {
    DBFilesystem *filesystem = [[DBFilesystem alloc] initWithAccount:account];
    [DBFilesystem setSharedFilesystem:filesystem];
    __weak id weakSelf = self;
    [DBFilesystem.sharedFilesystem addObserver:self block:^{
      [weakSelf updateView];
    }];
    [DBFilesystem.sharedFilesystem addObserver:self forPathAndChildren:DBPath.root block:^{
      [weakSelf updateView];
    }];
  }
  [self updateView];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
  if (section == 0) {
    return _fileInfos.count;
  }
  return 0;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
  PTATableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:reuseIdentifier];
  DBFileInfo *info = _fileInfos[indexPath.row];
  cell.textLabel.text = info.path.name;
  cell.detailTextLabel.text = [_dateFormatter stringFromDate:info.modifiedTime];
//  cell.textLabel.text = _dummyStrings[indexPath.row];
//  cell.detailTextLabel.text = @"August 12, 1989";
  return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
  DBFileInfo *fileInfo = _fileInfos[indexPath.row];
  NSError *error;
  DBFile *file = [DBFilesystem.sharedFilesystem openFile:fileInfo.path error:&error];
  NSAssert(!error, error.localizedDescription);

  PTADocumentViewController *vc = [[PTADocumentViewController alloc] init];
  vc.file = file;

  [self.navigationController pushViewController:vc animated:YES];
}

#pragma mark - Private

- (void)updateView {
  NSError *error;
  if (!DBFilesystem.sharedFilesystem.completedFirstSync) {
    _spinnerView.hidden = NO;
    _fileInfos = nil;
  } else {
    _spinnerView.hidden = YES;
    _fileInfos = [[DBFilesystem.sharedFilesystem listFolder:[DBPath root] error:&error] pta_filteredArrayWithPathExtension:@"txt"];
    NSAssert(!error, error.localizedDescription);
  }
  [_tableView reloadData];
}

- (void)handleAddTapped:(id)sender {
  NSLog(@"Add!");
}

@end
