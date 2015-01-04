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
#import "PTAAppendTextSelectionViewController.h"
#import "UIView+Toast.h"

@interface PTADocumentViewController ()<PTADocumentViewDelegate, PTAFileObserver, PTAAppendTextSelectionDelegate>
@property(nonatomic, strong) PTAFile *file;
@end

@implementation PTADocumentViewController {
  PTADocumentView *_documentView;

  DBPath *_path;
  PTAFilesystemManager *_filesystemManager;
  UIAlertController *_newVersionAlertController;
  NSRange _selectedCharacterRange;

  RXPromise *_currentPromise;

  UIBarButtonItem *_composeBarButton;
  UIBarButtonItem *_sendToBarButton;
}

- (void)dealloc {
  [_currentPromise cancel];
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

    UIAlertAction *action = [UIAlertAction actionWithTitle:@"Update"
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

  [_currentPromise cancel];
  _currentPromise = [_filesystemManager fileForPath:_path];
  __weak id weakSelf = self;
  _currentPromise.thenOnMain(^id(PTAFile *file) {
    PTADocumentViewController *strongSelf = weakSelf;
    strongSelf.file = file;
    [strongSelf updateView];
    return self;
  }, nil);
}

- (void)viewWillDisappear:(BOOL)animated {
  [super viewWillDisappear:animated];
  [_filesystemManager removeFileObserver:self forPath:_path];
}

#pragma mark - PTAFileObserver

- (void)fileDidChange:(PTAFile *)file {
  NSAssert(file, @"file must be non-nil.");
  _file = file;
  [self updateView];
}

#pragma mark - PTADocumentViewDelegate

- (void)documentView:(PTADocumentView *)documentView didChangeText:(NSString *)text {
  [_currentPromise cancel];

  _currentPromise = [_filesystemManager writeString:text toFileAtPath:_path];
  __weak id weakSelf = self;
  _currentPromise.thenOnMain(^PTAFile *(PTAFile *file) {
    PTADocumentViewController *strongSelf = weakSelf;
    strongSelf.file = file;
    strongSelf->_selectedCharacterRange = PTANullRange;
    [strongSelf updateView];
    return file;
  }, nil);
}

- (void)documentViewDidTapToCancelSelection:(PTADocumentView *)documentView {
  _selectedCharacterRange = PTANullRange;
  [self updateView];
}

- (void)documentView:(PTADocumentView *)documentView didDragToHighlightCharacterRange:(NSRange)range {
  if (PTARangeEmptyOrNotFound(range)) {
    _selectedCharacterRange = PTANullRange;
  } else {
    NSRange initialCharacterRange = NSMakeRange(range.location, 1);
    NSRange selectedCharacterRange = [documentView.text paragraphRangeForRange:initialCharacterRange];
    NSString *selectedString = [documentView.text substringWithRange:selectedCharacterRange];
    _selectedCharacterRange =
        [selectedString containsNonWhitespaceCharacters] ? selectedCharacterRange : PTANullRange;
  }
  [self updateView];
}

- (void)documentView:(PTADocumentView *)documentView
        removedRange:(NSRange)range
     andInsertedText:(NSString *)newText
          inLocation:(NSUInteger)location {
  NSParameterAssert(!PTARangeEmptyOrNotFound(range));
  NSString *textWithSelectedTextRemoved = [_file.content stringByReplacingCharactersInRange:range
                                                                                 withString:@""];
  NSString *newContent = [textWithSelectedTextRemoved stringByReplacingCharactersInRange:NSMakeRange(location, 0)
                                                                              withString:newText];

  [_currentPromise cancel];
  _currentPromise = [_filesystemManager writeString:newContent toFileAtPath:_path];
  
  __weak id weakSelf = self;
  _currentPromise.thenOnMain(^PTAFile *(PTAFile *file) {
    PTADocumentViewController *strongSelf = weakSelf;
    strongSelf.file = file;
    strongSelf->_selectedCharacterRange = PTANullRange;
    [strongSelf updateView];
    return file;
  }, nil);
}

#pragma mark - PTAAppendTextSelectionDelegate

- (void)appendTextControllerDidComplete:(PTAAppendTextSelectionViewController *)controller
                               withPath:(DBPath *)path {
  NSParameterAssert(path);
  
  [self dismissViewControllerAnimated:YES completion:nil];
  if ([path isEqual:_file.info.path]) {
    return;
  }

  NSRange oldSelectedCharacterRange = _selectedCharacterRange;
  _selectedCharacterRange = PTANullRange;
  
  NSString *remainderText = [_documentView.text stringByReplacingCharactersInRange:oldSelectedCharacterRange
                                                                        withString:@""];

  // Remove text from existing file
  [_currentPromise cancel];
  _currentPromise = [_filesystemManager writeString:remainderText toFileAtPath:_file.info.path];
  
  __weak id weakSelf = self;
  _currentPromise.thenOnMain(^PTAFile *(PTAFile *file) {
    PTADocumentViewController *strongSelf = weakSelf;
    strongSelf.file = file;
    [strongSelf updateView];
    return file;
  }, nil);
}

- (void)appendTextControllerDidCancel:(PTAAppendTextSelectionViewController *)controller {
  [self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - Private

- (void)handleAddToFileTapped:(id)sender {
  NSString *appendText = [_documentView.text substringWithRange:_selectedCharacterRange];
  PTAAppendTextSelectionViewController *appendTextController =
      [[PTAAppendTextSelectionViewController alloc] initWithFilesystemManager:_filesystemManager
                                                                   appendText:appendText];
  appendTextController.delegate = self;
//  PTADocumentCollectionSelection callback = ^(PTADocumentCollectionViewController *collectionController,
//                                              DBPath *path) {
//    [weakSelf documentCollectionDidSelectPath:path];
//  };
//  PTADocumentCollectionViewController *collectionController =
//      [[PTADocumentCollectionViewController alloc] initWithFilesystemManager:_filesystemManager
//                                                                    callback:callback];
//  collectionController.navigationItem.leftBarButtonItem =
//      [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemStop
//                                                    target:self
//                                                    action:@selector(handleDocumentControllerCancelled:)];

  UINavigationController *navigationController =
      [[UINavigationController alloc] initWithRootViewController:appendTextController];

  [self presentViewController:navigationController animated:YES completion:nil];
}

- (void)handleDocumentControllerCancelled:(id)sender {
  [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)updateView {
  NSString *text;
  BOOL showLoading = NO;
  BOOL isNewVersionAlertVisible = NO;

  if (!_file) {
    // Everything is hidden
  } else if (_file.newerVersionStatus != kPTAFileNewerVersionStatusNone) {
    isNewVersionAlertVisible = YES;
  } else if (!_file.isOpen || !_file.cached) {
    showLoading = YES;
  } else {
    text = _file.content;
  }

  BOOL animateRightBarButtom = (self.navigationItem.rightBarButtonItem != nil);
  BOOL hasSelection = !PTARangeEmptyOrNotFound(_selectedCharacterRange);
  if (hasSelection && self.navigationItem.rightBarButtonItem != _sendToBarButton) {
    [self.navigationItem setRightBarButtonItem:_sendToBarButton animated:animateRightBarButtom];
  } else if (!hasSelection && self.navigationItem.rightBarButtonItem != _composeBarButton) {
    [self.navigationItem setRightBarButtonItem:_composeBarButton animated:animateRightBarButtom];
  }
  self.navigationItem.title = _file ? _file.nameWithEmojiStatus : _path.name;

  if (isNewVersionAlertVisible && ![_newVersionAlertController pta_isActive]) {
    [self presentViewController:_newVersionAlertController animated:YES completion:nil];
  } else if (!isNewVersionAlertVisible && [_newVersionAlertController pta_isActive]) {
    [self dismissViewControllerAnimated:YES completion:nil];
  }
  
  PTADocumentViewModel *vm = [[PTADocumentViewModel alloc] initWithLoading:showLoading
                                                                      text:text
                                                    selectedCharacterRange:_selectedCharacterRange];
  [_documentView setViewModel:vm];
}

@end
