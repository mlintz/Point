//
//  PTATextEditorViewController.m
//  Point
//
//  Created by Mikey Lintz on 7/4/14.
//  Copyright (c) 2014 Mikey Lintz. All rights reserved.
//

#import "PTATextEditorViewController.h"

#import "PTATextEditorView.h"

@interface PTATextEditorViewController ()<PTATextEditorDelegateProtocol>
@end

@implementation PTATextEditorViewController {
  PTATextEditorView *_textEditorView;
}

#pragma mark - UIViewController

- (void)loadView {
  _textEditorView = [[PTATextEditorView alloc] init];
  _textEditorView.delegate = self;
  _textEditorView.text = @"foo";
  self.view = _textEditorView;
}

#pragma mark - PTATextEditorDelegateProtocol

- (NSString *)textEditorView:(PTATextEditorView *)view
    selectionStringForCharacterIndex:(NSUInteger)characterIndex {
  return @"bar";
}

@end
