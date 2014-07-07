//
//  PTATextEditorViewController.m
//  Point
//
//  Created by Mikey Lintz on 7/4/14.
//  Copyright (c) 2014 Mikey Lintz. All rights reserved.
//

#import "PTATextEditorViewController.h"

#import "PTATextEditorView.h"
#import "PTAParser.h"

@interface PTATextEditorViewController ()<PTATextEditorDelegateProtocol>
@end

@implementation PTATextEditorViewController {
  PTATextEditorView *_textEditorView;
  PTAParser *_cachedParser;
}

#pragma mark - UIViewController

- (void)loadView {
  _textEditorView = [[PTATextEditorView alloc] init];
  _textEditorView.delegate = self;
  _textEditorView.text = @"foo\nioapuwfopausdfp\nq47856989wieyuaoisdf\nkajshdflajhsdflkhasvklhakjsyroiuhfljzhsdlkfhoiuesryzoishdfysoi\nq763458796opoqiwepoiu\n\n\n\n\niawyerioaoiusydf\n.,zjsioyihiyewoiha\n\n\n\njarht\niowuer\n7685324\n08er8-8w\n\n\nfoo\nioapuwfopausdfp\nq47856989wieyuaoisdf\nkajshdflajhsdflkhasvklhakjsyroiuhfljzhsdlkfhoiuesryzoishdfysoi\nq763458796opoqiwepoiu\n\n\n\n\niawyerioaoiusydf\n.,zjsioyihiyewoiha\n\n\n\njarht\niowuer\n7685324\n08er8-8w\n\n\nfoo\nioapuwfopausdfp\nq47856989wieyuaoisdf\nkajshdflajhsdflkhasvklhakjsyroiuhfljzhsdlkfhoiuesryzoishdfysoi\nq763458796opoqiwepoiu\n\n\n\n\niawyerioaoiusydf\n.,zjsioyihiyewoiha\n\n\n\njarht\niowuer\n7685324\n08er8-8w\n\n\nfoo\nioapuwfopausdfp\nq47856989wieyuaoisdf\nkajshdflajhsdflkhasvklhakjsyroiuhfljzhsdlkfhoiuesryzoishdfysoi\nq763458796opoqiwepoiu\n\n\n\n\niawyerioaoiusydf\n.,zjsioyihiyewoiha\n\n\n\njarht\niowuer\n7685324\n08er8-8w\n\n\n";
  self.view = _textEditorView;
}

#pragma mark - PTATextEditorDelegateProtocol

- (NSRange)textEditorView:(PTATextEditorView *)textEditorView
    selectionRangeForCharacterIndex:(NSUInteger)characterIndex {
  PTAParser *parser = [self parserForString:textEditorView.text];
  return [parser selectionRangeForCharacterIndex:characterIndex];
}

- (BOOL)textEditorView:(PTATextEditorView *)textEditorView
    shouldStartSelectionAtCharacterIndex:(NSUInteger)characterIndex {
  NSRange composedRange =
      [textEditorView.text rangeOfComposedCharacterSequenceAtIndex:characterIndex];
  NSString *composedString = [_textEditorView.text substringWithRange:composedRange];
  return [composedString containsNonWhitespaceCharacters];
}

#pragma mark - Private

- (PTAParser *)parserForString:(NSString *)string {
  if (![string isEqualToString:_cachedParser.string]) {
    _cachedParser = [PTAParser parserForString:string];
  }
  return _cachedParser;
}

@end
