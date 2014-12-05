//
//  PTAAppendFileOperation.m
//  Point
//
//  Created by Mikey Lintz on 12/1/14.
//  Copyright (c) 2014 Mikey Lintz. All rights reserved.
//

#import "PTAAppendFileOperation.h"

static NSString *kAppendPrefix = @" - ";

@implementation PTAAppendFileOperation {
  NSString *_appendText;
}

+ (instancetype)operationWithAppendText:(NSString *)appendText {
  NSParameterAssert(appendText);
  NSParameterAssert(appendText.length);
  PTAAppendFileOperation *operation = [[self alloc] init];
  if (operation) {
    operation->_appendText = [[self formattedAppendString:appendText] copy];
  }
  return operation;
}

- (NSString *)contentByApplyingOperationToContent:(NSString *)fileContent {
  NSString *trimmedContent = [fileContent pta_terminatesInNewline]
      ? [fileContent pta_stringByTrimmingTerminatingCharactersInSet:[NSCharacterSet newlineCharacterSet]]
      : fileContent;
  return [trimmedContent stringByAppendingString:_appendText];
}

+ (NSString *)formattedAppendString:(NSString *)string {
  NSString *appendPrefixTrimmedString = string;
  while ([appendPrefixTrimmedString hasPrefix:kAppendPrefix]) {
    appendPrefixTrimmedString = appendPrefixTrimmedString.length > kAppendPrefix.length
        ? [appendPrefixTrimmedString substringFromIndex:[kAppendPrefix length]]
        : @"";
  }
  NSString *newlineTrimmedString =
      [appendPrefixTrimmedString stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
  return [NSString stringWithFormat:@"\n%@%@", kAppendPrefix, newlineTrimmedString];
}

@end
