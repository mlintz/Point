//
//  PTAAppendTextSelectionViewController.m
//  Point
//
//  Created by Mikey Lintz on 11/15/14.
//  Copyright (c) 2014 Mikey Lintz. All rights reserved.
//

#import "PTAAppendTextSelectionViewController.h"

#import "PTADocumentCollectionViewController.h"
#import "UIView+Toast.h"

static const NSTimeInterval kToastInterval = 1;

@implementation PTAAppendTextSelectionViewController {
  PTAFilesystemManager *_manager;
  NSString *_appendText;
  PTADocumentCollectionViewController *_collectionVC;
}

- (instancetype)init {
  [self doesNotRecognizeSelector:_cmd];
  return nil;
}

- (instancetype)initWithFilesystemManager:(PTAFilesystemManager *)manager
                               appendText:(NSString *)text {
  NSParameterAssert(manager);
  NSParameterAssert(text);
  NSParameterAssert(text.length);
  self = [super init];
  if (self) {
    _manager = manager;
    _appendText = [text copy];
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemStop
                                                                                          target:self
                                                                                          action:@selector(didSelectClose:)];
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"New file"
                                                                              style:UIBarButtonItemStylePlain
                                                                             target:self
                                                                             action:@selector(didSelectNew:)];
    self.navigationItem.title = @"Select Recipient";
  }
  return self;
}

- (void)loadView {
  __weak id weakSelf = self;
  PTADocumentCollectionSelection callback = ^(PTADocumentCollectionViewController *collectionController,
                                              DBPath *path) {
    [weakSelf documentCollectionControllerDidSelectPath:path];
  };
  _collectionVC = [[PTADocumentCollectionViewController alloc] initWithFilesystemManager:_manager
                                                                                callback:callback];
  [self addChildViewController:_collectionVC];
  self.view = [[UIView alloc] init];
  [self.view addSubview:_collectionVC.view];
  [_collectionVC didMoveToParentViewController:self];
}

- (void)viewWillLayoutSubviews {
  [super viewWillLayoutSubviews];
  _collectionVC.view.frame = self.view.bounds;
}

- (void)documentCollectionControllerDidSelectPath:(DBPath *)path {
  NSParameterAssert(path);

  NSString *message = [NSString stringWithFormat:@"Added \"%@\" to %@",
                       [_appendText stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]],
                        path.name];
  [self.navigationController.visibleViewController.view.window makeToast:message
                                                                duration:kToastInterval
                                                                position:CSToastPositionCenter];

  [_manager appendString:_appendText toFileAtPath:path].thenOnMain(^id(id result) {
    [self.delegate appendTextControllerDidComplete:self withPath:path];
    return result;
  }, nil);
}

- (void)didSelectCreateFileWithName:(NSString *)name {
  NSString *filename = [NSString stringWithFormat:@"%@.txt", [[name lowercaseStringWithLocale:nil] pta_stringBySquashingWhitespace:@"_"]];
  NSString *message;
  if ([_manager containsFileWithName:filename]) {
    message = [NSString stringWithFormat:@"File %@ already exists", filename];
  } else {
    message = [NSString stringWithFormat:@"Created %@", filename];

    __weak id weakSelf = self;
    [_manager createFileWithName:filename].thenOnMain(^id(PTAFile *file) {
      PTAAppendTextSelectionViewController *strongSelf = weakSelf;
      if (!strongSelf) {
        return nil;
      }
      NSString *initialContent = [NSString stringWithFormat:@"// %@\n\n# Next tasks\n\n# Inbox",
                                  [name capitalizedStringWithLocale:nil]];
      return [strongSelf->_manager writeString:initialContent
                                  toFileAtPath:file.info.path];
    }, nil)
    .thenOnMain(^id(PTAFile *file) {
      PTAAppendTextSelectionViewController *strongSelf = weakSelf;
      if (!strongSelf) {
        return nil;
      }
      return [strongSelf->_manager appendString:strongSelf->_appendText
                                   toFileAtPath:file.info.path];
    }, nil)
    .thenOnMain(^id(PTAFile *file) {
      PTAAppendTextSelectionViewController *strongSelf = weakSelf;
      [strongSelf.delegate appendTextControllerDidComplete:strongSelf withPath:file.info.path];
      return file;
    }, nil);
  }
  [self.view.window makeToast:message duration:kToastInterval position:CSToastPositionCenter];
}

- (void)didSelectNew:(id)sender {
  UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"New File"
                                                                           message:nil
                                                                    preferredStyle:UIAlertControllerStyleAlert];
  [alertController addTextFieldWithConfigurationHandler:^(UITextField *textField) {
    textField.placeholder = @"Name";
  }];
  
  UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:nil];
  [alertController addAction:cancelAction];

  __weak id weakSelf = self;
  UIAlertAction *createAction = [UIAlertAction actionWithTitle:@"Create" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
    UITextField *field = [alertController.textFields firstObject];
    [weakSelf didSelectCreateFileWithName:field.text];
  }];
  [alertController addAction:createAction];
  
  [self presentViewController:alertController animated:YES completion:nil];
}

- (void)didSelectClose:(id)sender {
  [self.delegate appendTextControllerDidCancel:self];
}

@end
