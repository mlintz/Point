//
//  PTAParser.m
//  Point
//
//  Created by Mikey Lintz on 7/4/14.
//  Copyright (c) 2014 Mikey Lintz. All rights reserved.
//

#import "PTAParser.h"

typedef NS_ENUM(NSUInteger, PTALineRank) {
  PTALineRankListItem,
  PTALineRankListHead,
  PTALineRankNewLine,
  PTALineRankHeaderOne,
  PTALineRankHeaderMany,
};

static NSString *const kOneHeaderPrefix = @"#";
static NSString *const kManyHeaderPrefix = @"##";

static PTAParser *gCachedParser;

@implementation PTAParser

@synthesize string = _string;

+ (instancetype)parserForString:(NSString *)string {
  NSAssert(string, @"Expecting string.");
  if (![gCachedParser.string isEqualToString:string]) {
    gCachedParser = [[PTAParser alloc] initWithString:string];
  }
  return gCachedParser;
}

- (id)init {
  [self doesNotRecognizeSelector:_cmd];
  return nil;
}

- (instancetype)initWithString:(NSString *)string {
  NSAssert(string, @"Expecting string.");
  self = [super init];
  if (self) {
    _string = [string copy];
  }
  return self;
}

- (NSRange)selectionRangeForCharacterIndex:(NSUInteger)characterIndex {
  NSAssert(characterIndex < [_string length], @"characterIndex is out of range");

  NSRange selectionRange = [_string lineRangeForRange:NSMakeRange(characterIndex, 0)];
  PTALineRank startLineRank = [self lineRankForRange:selectionRange];
  NSAssert(startLineRank != PTALineRankNewLine, @"Shouldn't start parsing on a new line.");

  NSRange lineRange;
  PTALineRank lineRank;
  while (NSMaxRange(selectionRange) < [_string length]) {
    lineRange = [_string lineRangeForRange:NSMakeRange(NSMaxRange(selectionRange), 0)];
    lineRank = [self lineRankForRange:lineRange];
    if (lineRank >= startLineRank) {
      return selectionRange;
    }
    selectionRange.length += lineRange.length;
  }
  return selectionRange;
}

#pragma mark - Private

- (PTALineRank)lineRankForRange:(NSRange)range {
  NSString *substring = [_string substringWithRange:range];

  // Check if newline-only line
  NSScanner *scanner = [NSScanner scannerWithString:substring];
  scanner.charactersToBeSkipped = nil;
  [scanner scanCharactersFromSet:[NSCharacterSet newlineCharacterSet] intoString:NULL];
  if (scanner.isAtEnd) {
    return PTALineRankNewLine;
  }

  // Check if header line
  if ([substring hasPrefix:kManyHeaderPrefix]) {
    return PTALineRankHeaderMany;
  }
  if ([substring hasPrefix:kOneHeaderPrefix]) {
    return PTALineRankHeaderOne;
  }

  // Check if start of list
  if (range.location == 0) {
    return PTALineRankListHead;
  }
  NSRange previousLineRange = [_string lineRangeForRange:NSMakeRange(range.location - 1, 0)];
  if ([self lineRankForRange:previousLineRange] == PTALineRankNewLine) {
    return PTALineRankListHead;
  }

  return PTALineRankListItem;
}


@end
