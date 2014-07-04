//
//  PTATextEditorView.h
//  Point
//
//  Created by Mikey Lintz on 7/4/14.
//

@class PTATextEditorView;

@protocol PTATextEditorDelegateProtocol <NSObject>

- (NSString *)textEditorView:(PTATextEditorView *)view
    selectionStringForCharacterIndex:(NSUInteger)characterIndex;

@end

@interface PTATextEditorView : UIView

@property(nonatomic, copy) NSString *text;
@property(nonatomic, weak) NSObject<PTATextEditorDelegateProtocol> *delegate;

@end
