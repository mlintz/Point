//
//  PTAFileOperationAggregator.h
//  Point
//
//  Created by Mikey Lintz on 12/18/14.
//  Copyright (c) 2014 Mikey Lintz. All rights reserved.
//

@protocol PTAFileOperation;

@interface PTAFileOperationAggregator : NSObject<NSCoding>

// If this property is non-nil, then all methods will assert that they're being performed on queue.
// This value is not archived.
@property(nonatomic, strong) NSOperationQueue *queue;

+ (instancetype)aggregator;
- (void)addOperation:(id<PTAFileOperation>)operation forFileAtPath:(DBPath *)path;
- (BOOL)hasOperationForFileAtPath:(DBPath *)path;
- (void)removeAllOperationForFileAtPath:(DBPath *)path;

// Returns string if no operations are registered for the path.
- (NSString *)string:(NSString *)string withOperationsAppliedForPath:(DBPath *)path;

@end
