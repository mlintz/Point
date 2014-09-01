//
//  PTAFilePrivate.h
//  Point
//
//  Created by Mikey Lintz on 7/19/14.
//  Copyright (c) 2014 Mikey Lintz. All rights reserved.
//

#import "PTAFile.h"

@class DBFile;

@interface PTAFile (Private)

- (instancetype)initWithFile:(DBFile *)file;

@end
