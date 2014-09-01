//
//  PTADropboxViewController.m
//  Point
//
//  Created by Mikey Lintz on 7/6/14.
//  Copyright (c) 2014 Mikey Lintz. All rights reserved.
//

#import "PTADropboxViewController.h"

#import <Dropbox/Dropbox.h>

static NSString *const kTextViewFont = @"CourierNewPSMT";
static NSString *const kTextFileName = @"foo.txt";

@implementation PTADropboxViewController {
  NSObject *_observerHandle;
  UITextView *_textView;
  DBFile *_file;
}

- (id)init {
  self = [super init];
  if (self) {
    _observerHandle = [[NSObject alloc] init];
  }
  return self;
}

#pragma mark - UIViewController

- (void)loadView {
  _textView = [[UITextView alloc] init];
  _textView.font = [UIFont fontWithName:kTextViewFont size:16];
  _textView.delegate = self;
  self.view = _textView;
}

- (void)viewDidAppear:(BOOL)animated {
  [super viewDidAppear:animated];
  DBAccountManager *accountManager = [DBAccountManager sharedManager];
  if (!accountManager.linkedAccount) {
    [accountManager linkFromController:self];
  }
  DBAccount *account = [[DBAccountManager sharedManager] linkedAccount];
  DBFilesystem *filesystem = [[DBFilesystem alloc] initWithAccount:account];
  [DBFilesystem setSharedFilesystem:filesystem];
  __weak id weakSelf = self;
  [filesystem addObserver:_observerHandle block:^{
    PTADropboxViewController *strongSelf = weakSelf;
    [[DBFilesystem sharedFilesystem] removeObserver:strongSelf->_observerHandle];
    if (!_file) {
      [strongSelf fillTextData];
    }
  }];
}

- (void)fillTextData {
  DBPath *rootPath = [DBPath root];
  NSError *error;
  NSArray *fileInfos = [[DBFilesystem sharedFilesystem] listFolder:rootPath error:&error];
  NSAssert(error == nil, error.localizedDescription);
  DBFile *file;
  for (DBFileInfo *info in fileInfos) {
    if ([kTextFileName isEqualToString:info.path.name]) {
      file = [[DBFilesystem sharedFilesystem] openFile:info.path error:&error];
      NSAssert(error == nil, [error localizedDescription]);
    }
  }
  if (!file) {
    file = [[DBFilesystem sharedFilesystem] createFile:[[DBPath alloc] initWithString:kTextFileName] error:&error];
    NSAssert(error == nil, [error localizedDescription]);
  }
  _file = file;
  NSString *fileString = [_file readString:&error];
  NSLog(@"%@", fileString);
  __weak id weakSelf = self;
  [_file addObserver:_observerHandle block:^{
    PTADropboxViewController *strongSelf = weakSelf;
    NSError *error;
    if (strongSelf->_file.newerStatus.cached) {
      [strongSelf->_file update:&error];
      if (error) {
        NSLog(@"%@", error.localizedDescription);
        return;
      }
    }
    NSString *fileString = [strongSelf->_file readString:&error];
    if (error) {
      
    } else {
      strongSelf->_textView.text = fileString;
    }
  }];
}

- (void)handleLoginButtonTap {
  NSLog(@"tap!");
}

- (void)textViewDidChange:(UITextView *)textView {
  NSError *error;
  if (_file.status.cached) {
    [_file writeString:textView.text error:&error];
    NSAssert(error == nil, [error localizedDescription]);
  }
}

@end
