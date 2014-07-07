//
//  PTAAuthenticationValues.m
//  Point
//
//  Created by Mikey Lintz on 7/6/14.
//  Copyright (c) 2014 Mikey Lintz. All rights reserved.
//

#import "PTAAuthenticationValues.h"

static NSString *const kCredentialsFileName = @"credentials";
static NSString *const kCredentialsFileType = @"json";

static NSString *const kKeyJSONTag = @"key";
static NSString *const kSecretJSONTag = @"secret";

static NSString *gAppKey;
static NSString *gAppSecret;

@implementation PTAAuthenticationValues

+ (NSString *)key {
  if (!gAppKey) {
    [self fetchKeyAndSecret];
  }
  return gAppKey;
}

+ (NSString *)secret {
  if (!gAppSecret) {
    [self fetchKeyAndSecret];
  }
  return gAppSecret;
}

#pragma mark - Private

+ (void)fetchKeyAndSecret {
  NSString *path = [[NSBundle mainBundle] pathForResource:kCredentialsFileName
                                                   ofType:kCredentialsFileType];
  NSData *data = [NSData dataWithContentsOfFile:path];
  NSAssert(data, @"Missing credentials file.");

  NSError *error;
  NSDictionary *json = [NSJSONSerialization JSONObjectWithData:data options:0 error:&error];
  NSAssert(error == nil, @"Error reading json file: %@.", [error localizedDescription]);

  gAppKey = json[kKeyJSONTag];
  gAppSecret = json[kSecretJSONTag];
  NSAssert(gAppKey, @"App key is nil.");
  NSAssert(gAppSecret, @"App secret is nil.");
}

@end
