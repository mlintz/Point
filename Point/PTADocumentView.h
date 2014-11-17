//
//  PTADocumentView.h
//  Point
//
//  Created by Mikey Lintz on 11/16/14.
//  Copyright (c) 2014 Mikey Lintz. All rights reserved.
//

@class PTADocumentView;

@protocol PTADocumentViewDelegate <NSObject>

- (void)documentView:(PTADocumentView *)documentView didChangeTextInRange:(NSRange)range replacementText:(NSString *)text;
- (void)documentView:(PTADocumentView *)documentView didDragToHighlightCharacterRange:(NSRange)range;
- (void)documentViewDidDragToHighlightAllText:(PTADocumentView *)documentView;
- (void)documentViewDidTapToCancelSelection:(PTADocumentView *)documentView;

@end

// Immutable
@interface PTADocumentViewModel : NSObject

@property(nonatomic, readonly) BOOL isLoading;
@property(nonatomic, readonly) NSString *text;
@property(nonatomic, readonly) NSRange selectedCharacterRange;  // Location set to NSNotFound to indicate no selection

- (instancetype)initWithLoading:(BOOL)loading text:(NSString *)text selectedCharacterRange:(NSRange)range;

@end

@interface PTADocumentView : UIView

@property(nonatomic, weak) id<PTADocumentViewDelegate> delegate;
@property(nonatomic, readonly) NSString *text;

- (void)setViewModel:(PTADocumentViewModel *)viewModel;

@end
