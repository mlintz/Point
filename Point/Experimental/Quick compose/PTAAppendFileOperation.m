//
//  PTAAppendFileOperation.m
//  Point
//
//  Created by Mikey Lintz on 12/1/14.
//  Copyright (c) 2014 Mikey Lintz. All rights reserved.
//

#import "PTAAppendFileOperation.h"

static NSString *kAppendFormat = @"\n - %@";

@implementation PTAAppendFileOperation {
  NSString *_appendText;
}

+ (instancetype)operationWithAppendText:(NSString *)appendText {
  NSParameterAssert(appendText);
  NSParameterAssert(appendText.length);
  PTAAppendFileOperation *operation = [[self alloc] init];
  if (operation) {
    operation->_appendText = [[self formattedString:appendText] copy];
  }
  return operation;
}

- (NSString *)contentByApplyingOperationToContent:(NSString *)fileContent {
  NSString *trimmedContent = [fileContent pta_terminatesInNewline]
      ? [fileContent pta_stringByTrimmingTerminatingCharactersInSet:[NSCharacterSet newlineCharacterSet]]
      : fileContent;
  return [trimmedContent stringByAppendingString:_appendText];
}

+ (NSString *)formattedString:(NSString *)string {
  NSString *trimmedString =
      [string stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
  return [NSString stringWithFormat:kAppendFormat, trimmedString];
}

@end
