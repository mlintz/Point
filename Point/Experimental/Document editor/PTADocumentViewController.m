//
//  PTADocumentViewController.m
//  Point
//
//  Created by Mikey Lintz on 9/1/14.
//  Copyright (c) 2014 Mikey Lintz. All rights reserved.
//

#import "PTADocumentViewController.h"
#import "PTAComposeBarButtonItem.h"
#import "PTADocumentView.h"
#import "PTADocumentCollectionViewController.h"
#import "UIView+Toast.h"

@interface PTADocumentViewController ()<PTADocumentViewDelegate, PTAFileObserver>
@end

@implementation PTADocumentViewController {
  PTADocumentView *_documentView;

  DBPath *_path;
  PTAFile *_file;
  PTAFilesystemManager *_filesystemManager;
  UIAlertController *_newVersionAlertController;
  UIAlertController *_errorAlertController;
  NSRange _selectedCharacterRange;
  
  UIBarButtonItem *_composeBarButton;
  UIBarButtonItem *_sendToBarButton;
}

- (instancetype)init {
  [self doesNotRecognizeSelector:_cmd];
  return nil;
}

- (instancetype)initWithManager:(PTAFilesystemManager *)manager path:(DBPath *)path {
  NSParameterAssert(manager);
  NSParameterAssert(path);
  self = [super init];
  if (self) {
    _selectedCharacterRange = PTANullRange;
    _filesystemManager = manager;
    _path = path;

    _composeBarButton = [[PTAComposeBarButtonItem alloc] initWithController:self filesystemManager:_filesystemManager];
    _sendToBarButton = [[UIBarButtonItem alloc] initWithTitle:@"Send to file"
                                                        style:UIBarButtonItemStylePlain
                                                       target:self
                                                       action:@selector(handleAddToFileTapped:)];
    self.navigationItem.title = _path.name;
    self.navigationItem.rightBarButtonItem = _composeBarButton;

    __weak id weakSelf = self;
    UIAlertAction *action;
    action = [UIAlertAction actionWithTitle:@"OK"
                                      style:UIAlertActionStyleCancel
                                    handler:^(UIAlertAction *action) {
      [[weakSelf navigationController] popViewControllerAnimated:YES];
    }];
    NSString *message = [NSString stringWithFormat:@"File error: %@", _file.error.localizedDescription];
    _errorAlertController = [UIAlertController alertControllerWithTitle:@"Error"
                                                                message:message
                                                         preferredStyle:UIAlertControllerStyleAlert];
    [_errorAlertController addAction:action];

    action = [UIAlertAction actionWithTitle:@"Update"
                                      style:UIAlertActionStyleCancel
                                    handler:^(UIAlertAction *action) {
      [manager updateFileForPath:path];
    }];
    _newVersionAlertController = [UIAlertController alertControllerWithTitle:@"Alert"
                                                                     message:@"Newer version of file available"
                                                              preferredStyle:UIAlertControllerStyleAlert];
    [_newVersionAlertController addAction:action];
  }
  return self;
}

- (void)loadView {
  _documentView = [[PTADocumentView alloc] init];
  _documentView.delegate = self;
  PTADocumentViewModel *viewModel =
      [[PTADocumentViewModel alloc] initWithLoading:YES text:nil selectedCharacterRange:PTANullRange];
  [_documentView setViewModel:viewModel];
  self.view = _documentView;
}

- (void)viewDidAppear:(BOOL)animated {
  [super viewDidAppear:animated];
  [_filesystemManager addFileObserver:self forPath:_path];
  _file = [_filesystemManager openFileForPath:_path];
  NSAssert(!_file.error, @"Error opening file: %@", _file.error);
  [self updateView];
}

- (void)viewDidDisappear:(BOOL)animated {
  [super viewDidDisappear:animated];
  [_filesystemManager removeFileObserver:self forPath:_path];
  [_filesystemManager releaseFileForPath:_path];
}

#pragma mark - PTAFileObserver

- (void)fileDidChange:(PTAFile *)file {
  NSAssert(file, @"file must be non-nil.");
  _file = file;
  [self updateView];
}

#pragma mark - PTADocumentViewDelegate

- (void)documentView:(PTADocumentView *)documentView didChangeText:(NSString *)text {
  _file = [_filesystemManager writeString:text toFileAtPath:_path];
  NSAssert(!_file.error, @"Error writing to file: %@", _file.error);
  _selectedCharacterRange = PTANullRange;
  [self updateView];
}

- (void)documentViewDidTapToCancelSelection:(PTADocumentView *)documentView {
  _selectedCharacterRange = PTANullRange;
  [self updateView];
}

- (void)documentViewDidDragToHighlightAllText:(PTADocumentView *)documentView {
  if (![documentView.text containsNonWhitespaceCharacters]) {
    return;
  }
  _selectedCharacterRange = NSMakeRange(0, _documentView.text.length);
  [self updateView];
}

- (void)documentView:(PTADocumentView *)documentView didDragToHighlightCharacterRange:(NSRange)range {
  if (PTARangeEmptyOrNotFound(range)) {
    return;
  }
  if (![[documentView.text substringWithRange:range] containsNonWhitespaceCharacters]) {
    return;
  }

  NSRange oldCharacterRange = _selectedCharacterRange;
  _selectedCharacterRange = range;
  _selectedCharacterRange = [[self class] newlineBoundedRangeContainingRange:_selectedCharacterRange
                                                                    inString:documentView.text];
  if (oldCharacterRange.length > 0) {
    _selectedCharacterRange = NSUnionRange(oldCharacterRange, _selectedCharacterRange);
  }
  [self updateView];
}

- (void)documentCollectionDidSelectPath:(DBPath *)path {
  NSParameterAssert(path);
  
  [self dismissViewControllerAnimated:YES completion:nil];
  if ([path isEqual:_file.info.path]) {
    return;
  }
  NSString *toastMessage = [NSString stringWithFormat:@"Sent text to %@", path.name];
  [self.navigationController.visibleViewController.view.window makeToast:toastMessage duration:0.5f position:CSToastPositionCenter];

  NSRange oldSelectedCharacterRange = _selectedCharacterRange;
  _selectedCharacterRange = PTANullRange;
  
  NSString *selectedText = [_documentView.text substringWithRange:oldSelectedCharacterRange];
  NSString *remainderText = [_documentView.text stringByReplacingCharactersInRange:oldSelectedCharacterRange withString:@""];

  // Append text to new path
  PTAFile *newFile = [_filesystemManager openFileForPath:path];
  NSAssert(!newFile.error, @"Error opening file for append: %@", newFile.error);
  newFile = [_filesystemManager appendString:selectedText toFileAtPath:path];
  NSAssert(!newFile.error, @"Error appending text (%@) to file: %@", selectedText, newFile.error);
  [_filesystemManager releaseFileForPath:path];

  // Remove text from existing file
  [_filesystemManager openFileForPath:_file.info.path];  // Re-open file in case file was closed in viewDidDisappear.
  _file = [_filesystemManager writeString:remainderText toFileAtPath:_file.info.path];
  NSAssert(!_file.error, @"Error writing text (%@) to file: %@", remainderText, _file.error);
  [_filesystemManager releaseFileForPath:_file.info.path];

  [self updateView];
}

#pragma mark - Private

- (void)handleAddToFileTapped:(id)sender {
  __weak id weakSelf = self;
  PTADocumentCollectionSelection callback = ^(PTADocumentCollectionViewController *collectionController,
                                              DBPath *path) {
    [weakSelf documentCollectionDidSelectPath:path];
  };
  PTADocumentCollectionViewController *collectionController =
      [[PTADocumentCollectionViewController alloc] initWithFilesystemManager:_filesystemManager
                                                                    callback:callback];
  collectionController.navigationItem.leftBarButtonItem =
      [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemStop
                                                    target:self
                                                    action:@selector(handleDocumentControllerCancelled:)];

  UINavigationController *navigationController =
      [[UINavigationController alloc] initWithRootViewController:collectionController];

  [self presentViewController:navigationController animated:YES completion:nil];
}

- (void)handleDocumentControllerCancelled:(id)sender {
  [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)updateView {
  NSString *text;
  BOOL showLoading = NO;
  BOOL isNewVersionAlertVisible = NO;
  BOOL isErrorAlertVisible = NO;

  BOOL animateRightBarButtom = (self.navigationItem.rightBarButtonItem != nil);
  BOOL hasSelection = !PTARangeEmptyOrNotFound(_selectedCharacterRange);
  if (hasSelection && self.navigationItem.rightBarButtonItem != _sendToBarButton) {
    [self.navigationItem setRightBarButtonItem:_sendToBarButton animated:animateRightBarButtom];
  } else if (!hasSelection && self.navigationItem.rightBarButtonItem != _composeBarButton) {
    [self.navigationItem setRightBarButtonItem:_composeBarButton animated:animateRightBarButtom];
  }

  if (!_file) {
    // Everything is hidden
  } else if (_file.error) {
    isErrorAlertVisible = YES;
  } else if (_file.hasNewerVersion) {
    isNewVersionAlertVisible = YES;
  } else if (!_file.isOpen || !_file.cached) {
    showLoading = YES;
  } else {
    text = _file.content;
  }

  if (isNewVersionAlertVisible && ![_newVersionAlertController pta_isActive]) {
    [self presentViewController:_newVersionAlertController animated:YES completion:nil];
  } else if (!isNewVersionAlertVisible && [_newVersionAlertController pta_isActive]) {
    [self dismissViewControllerAnimated:YES completion:nil];
  }
  
  if (isErrorAlertVisible && ![_errorAlertController pta_isActive]) {
    [self presentViewController:_errorAlertController animated:YES completion:nil];
  } else if (!isErrorAlertVisible && [_errorAlertController pta_isActive]) {
    [self dismissViewControllerAnimated:YES completion:nil];
  }

  PTADocumentViewModel *vm = [[PTADocumentViewModel alloc] initWithLoading:showLoading
                                                                      text:text
                                                    selectedCharacterRange:_selectedCharacterRange];
  [_documentView setViewModel:vm];
}

+ (NSRange)newlineBoundedRangeContainingRange:(NSRange)range inString:(NSString *)string {
  if (PTARangeEmptyOrNotFound(range)) {
    return range;
  }

  NSCharacterSet *newlineCharacters = [NSCharacterSet newlineCharacterSet];
  NSRange preRange = NSMakeRange(0, range.location);
  NSRange prependingNewline = [string rangeOfCharacterFromSet:newlineCharacters options:NSBackwardsSearch range:preRange];
  NSUInteger newLocation = PTARangeEmptyOrNotFound(prependingNewline) ? 0 : NSMaxRange(prependingNewline);

  NSRange postRange = NSMakeRange(range.location, string.length - range.location);
  NSRange postpendingNewline = [string rangeOfCharacterFromSet:newlineCharacters options:0 range:postRange];
  NSUInteger newLength = PTARangeEmptyOrNotFound(postpendingNewline)
      ? string.length - newLocation
      : NSMaxRange(postpendingNewline) - newLocation;
  
  return NSMakeRange(newLocation, newLength);
}

@end