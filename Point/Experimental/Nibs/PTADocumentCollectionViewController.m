//
//  PTADocumentCollectionViewController.m
//  Point
//
//  Created by Mikey Lintz on 8/31/14.
//  Copyright (c) 2014 Mikey Lintz. All rights reserved.
//

#import "PTADocumentCollectionViewController.h"

#import "PTADocumentListCollectionViewCell.h"

static NSString *reuseIdentifier = @"PTACollectionViewReuseIdentifier";

@interface PTATableViewCell : UITableViewCell
@end

@implementation PTATableViewCell

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
  return [super initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:reuseIdentifier];
}

@end

@implementation PTADocumentCollectionViewController {
  UITableView *_tableView;
  NSArray *_dummyStrings;
}

- (id)init {
  self = [super init];
  if (self) {
    _dummyStrings = @[@"alpha", @"bravo", @"charlie", @"dogtrot", @"echo"];
    self.navigationItem.title = @"All Documents";
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd
                                                                                           target:self
                                                                                           action:@selector(handleAddTapped:)];
  }
  return self;
}

- (void)loadView {
  _tableView = [[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStylePlain];
  _tableView.dataSource = self;
  [_tableView registerClass:[PTATableViewCell class] forCellReuseIdentifier:reuseIdentifier];
  
  self.view = _tableView;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
  if (section == 0) {
    return _dummyStrings.count;
  }
  return 0;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
  PTATableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:reuseIdentifier];
  cell.textLabel.text = _dummyStrings[indexPath.row];
  cell.detailTextLabel.text = @"August 12, 1989";
  return cell;
}

- (void)handleAddTapped:(id)sender {
  NSLog(@"Add!");
}

@end
