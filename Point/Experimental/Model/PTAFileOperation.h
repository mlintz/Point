//
//  PTAFileOperation.h
//  Point
//
//  Created by Mikey Lintz on 12/1/14.
//  Copyright (c) 2014 Mikey Lintz. All rights reserved.
//

@class PTAFile;

@protocol PTAFileOperation<NSObject, NSCoding, NSCopying>

- (NSString *)contentByApplyingOperationToContent:(NSString *)fileContent;

@end
