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

@interface PTADocumentViewController ()<PTADocumentViewDelegate, PTAFileObserver>
@end

@implementation PTADocumentViewController {
  PTADocumentView *_documentView;

  DBPath *_path;
  PTAFile *_file;
  PTAFilesystemManager *_filesystemManager;
  UIAlertController *_newVersionAlertController;
  UIAlertController *_errorAlertController;
  NSRange _selectedGlyphRange;
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
    _selectedGlyphRange = NSMakeRange(NSNotFound, 0);
    _filesystemManager = manager;
    _path = path;

    self.navigationItem.title = _path.name;
    self.navigationItem.rightBarButtonItem =
        [[PTAComposeBarButtonItem alloc] initWithController:self filesystemManager:_filesystemManager];

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
      [[PTADocumentViewModel alloc] initWithLoading:YES text:nil selectedGlyphRange:NSMakeRange(NSNotFound, 0)];
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
  _file = nil;
}

#pragma mark - PTAFileObserver

- (void)fileDidChange:(PTAFile *)file {
  NSAssert(file, @"file must be non-nil.");
  _file = file;
  [self updateView];
}

#pragma mark - PTADocumentViewDelegate

- (void)documentView:(PTADocumentView *)documentView didChangeTextInRange:(NSRange)range replacementText:(NSString *)text {
  [_filesystemManager writeString:documentView.text toFileAtPath:_path];
}

- (void)documentViewDidTapToCancelSelection:(PTADocumentView *)documentView {
  _selectedGlyphRange = NSMakeRange(NSNotFound, 0);
  [self updateView];
}

- (void)documentViewDidDragToHighlightAllText:(PTADocumentView *)documentView {
  _selectedGlyphRange = NSMakeRange(0, _documentView.text.length);
  [self updateView];
}

- (void)documentView:(PTADocumentView *)documentView didDragToHighlightGlyphRange:(NSRange)range {

}

#pragma mark - Private

- (void)updateView {
  NSString *text;
  BOOL showLoading = NO;
  BOOL isNewVersionAlertVisible = NO;
  BOOL isErrorAlertVisible = NO;

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

  PTADocumentViewModel *vm = [[PTADocumentViewModel alloc] initWithLoading:showLoading text:text selectedGlyphRange:_selectedGlyphRange];
  [_documentView setViewModel:vm];
}

@end
