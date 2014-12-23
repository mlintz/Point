//
//  PTAAppendFileOperation.m
//  Point
//
//  Created by Mikey Lintz on 12/1/14.
//  Copyright (c) 2014 Mikey Lintz. All rights reserved.
//

#import "PTAAppendFileOperation.h"

static NSString *kAppendPrefix = @" - ";
static NSString * const kAppendTextKey = @"PTAAppendFileOperation.appendText";

@implementation PTAAppendFileOperation {
  NSString *_appendText;
}

+ (instancetype)operationWithAppendText:(NSString *)appendText {
  return [[self alloc] initWithAppendText:appendText];
}

- (instancetype)init {
  [self doesNotRecognizeSelector:_cmd];
  return nil;
}

- (instancetype)initWithAppendText:(NSString *)appendText {
  NSParameterAssert(appendText);
  NSParameterAssert(appendText.length);
  self = [super init];
  if (self) {
    _appendText = [[self.class formattedAppendString:appendText] copy];
  }
  return self;
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

#pragma mark - NSCopying

- (id)copyWithZone:(NSZone *)zone {
  return self;
}

#pragma mark - NSCoding

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
  NSString *appendText = [aDecoder decodeObjectOfClass:[NSString class]
                                                forKey:kAppendTextKey];
  return [self initWithAppendText:appendText];
}

- (void)encodeWithCoder:(NSCoder *)aCoder {
  [aCoder encodeObject:_appendText forKey:kAppendTextKey];
}

@end
