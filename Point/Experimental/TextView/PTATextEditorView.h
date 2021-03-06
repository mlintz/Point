//
//  PTATextEditorView.h
//  Point
//
//  Created by Mikey Lintz on 7/4/14.
//

@class PTATextEditorView;

@protocol PTATextEditorDelegateProtocol <NSObject>

- (NSRange)textEditorView:(PTATextEditorView *)view
    selectionRangeForCharacterIndex:(NSUInteger)characterIndex;
- (BOOL)textEditorView:(PTATextEditorView *)view
    shouldStartSelectionAtCharacterIndex:(NSUInteger)characterIndex;

@end

@interface PTATextEditorView : UIView

@property(nonatomic, copy) NSString *text;
@property(nonatomic, weak) NSObject<PTATextEditorDelegateProtocol> *delegate;

@end
