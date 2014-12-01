//
//  PTAAppendFileOperation.h
//  Point
//
//  Created by Mikey Lintz on 12/1/14.
//  Copyright (c) 2014 Mikey Lintz. All rights reserved.
//

#import "PTAFileOperation.h"

@interface PTAAppendFileOperation : NSObject<PTAFileOperation>
+ (instancetype)operationWithAppendText:(NSString *)appendText;
@end
