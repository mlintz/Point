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

@implementation PTADropboxViewController {
  NSObject *_observerHandle;
}

- (id)init {
  self = [super init];
  if (self) {
    _observerHandle = [[NSObject alloc] init];
  }
  return self;
}

#pragma mark - UIViewController

- (void)viewDidAppear:(BOOL)animated {
  [super viewDidAppear:animated];
  DBAccountManager *accountManager = [DBAccountManager sharedManager];
  if (accountManager.linkedAccount) {
    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Success"
                                                        message:@"Account linked successfully."
                                                       delegate:nil
                                              cancelButtonTitle:@"Alright!!"
                                              otherButtonTitles:nil];
    [alertView show];

    DBAccount *account = [[DBAccountManager sharedManager] linkedAccount];
    DBFilesystem *filesystem = [[DBFilesystem alloc] initWithAccount:account];
    [DBFilesystem setSharedFilesystem:filesystem];
    __weak PTADropboxViewController *weakSelf = self;
    [filesystem addObserver:_observerHandle block:^{
      PTADropboxViewController *strongSelf = weakSelf;
      [strongSelf listFiles];
    }];

    NSLog(@"completedFirstSync: %@", filesystem.completedFirstSync ? @"YES" : @"NO");
  } else {
    [accountManager linkFromController:self];
  }
}

- (void)loadView {
  self.view = [[UIView alloc] init];
  self.view.backgroundColor = [UIColor whiteColor];
}

- (void)listFiles {
  DBPath *path = [DBPath root];
  NSError *error;
  NSArray *fileInfos = [[DBFilesystem sharedFilesystem] listFolder:path error:&error];
  NSAssert(error == nil, @"Error listing folders.");
  NSLog(@"Filenames:\n----------");
  for (DBFileInfo *info in fileInfos) {
    NSLog(@"\tFilename:%@", info.path.name);
  }
}

- (void)handleLoginButtonTap {
  NSLog(@"tap!");
}

@end
