//
//  PTAFile.h
//  Point
//
//  Created by Mikey Lintz on 7/19/14.
//  Copyright (c) 2014 Mikey Lintz. All rights reserved.
//

@class BFTask;
@class PTAFile;

typedef void (^PTAFileContentsChanged)(PTAFile *file, NSString *text);

typedef NS_ENUM(NSInteger, PTAFileState) {
  PTAFileStateUploading,
  PTAFileStateDownloading,
  PTAFileStateIdle,
};

@interface PTAFile : NSObject

@property(nonatomic, readonly) PTAFileState state;
@property(nonatomic, readonly) NSString *name;
@property(nonatomic, readonly) NSDate *lastModified;
@property(nonatomic, copy) PTAFileContentsChanged changeCallback;

- (BFTask *)getText;  // NSString
- (void)setText:(NSString *)text error:(NSError **)error;
- (void)appendText:(NSString *)text error:(NSError **)error;

@end
