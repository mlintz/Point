//
//  PTADocumentView.h
//  Point
//
//  Created by Mikey Lintz on 11/16/14.
//  Copyright (c) 2014 Mikey Lintz. All rights reserved.
//

@class PTADocumentView;

// Immutable
@interface PTADocumentViewModel : NSObject

@property(nonatomic, readonly) BOOL isLoading;
@property(nonatomic, readonly) NSString *text;
@property(nonatomic, readonly) NSRange selectedCharacterRange;  // Location set to NSNotFound to indicate no selection

- (instancetype)initWithLoading:(BOOL)loading text:(NSString *)text selectedCharacterRange:(NSRange)range;

@end

@protocol PTADocumentViewDelegate <NSObject>

// Return nil to change nothing.
- (void)documentView:(PTADocumentView *)documentView didChangeText:(NSString *)text;
- (void)documentView:(PTADocumentView *)documentView didDragToHighlightCharacterRange:(NSRange)range;
- (void)documentViewDidDragToHighlightAllText:(PTADocumentView *)documentView;
- (void)documentViewDidTapToCancelSelection:(PTADocumentView *)documentView;

@end

@interface PTADocumentView : UIView

@property(nonatomic, weak) id<PTADocumentViewDelegate> delegate;
@property(nonatomic, readonly) NSString *text;

- (void)setViewModel:(PTADocumentViewModel *)viewModel;

@end