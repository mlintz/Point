//
//  PTAParser.h
//  Point
//
//  Created by Mikey Lintz on 7/4/14.
//  Copyright (c) 2014 Mikey Lintz. All rights reserved.
//

@interface PTAParser : NSObject

@property(nonatomic, readonly) NSString *string;

+ (instancetype)parserForString:(NSString *)string;

- (BOOL)isCharacterIndexInNewlineOnlyLine:(NSUInteger)characterIndex;
// Asserts if characterIndex is in a line containing only newline characters
- (NSRange)selectionRangeForCharacterIndex:(NSUInteger)characterIndex;

@end
