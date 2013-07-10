//
//  QiniuResumableUpload.h
//  ResumalbleUpload
//
//  Created by 时 嘉赟 on 6/30/13.
//  Copyright (c) 2013 时 嘉赟. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "QiniuBlockUploadDelegate.h"
#import "QiniuUploadDelegate.h"

@interface QiniuResumableUpload : NSObject<QiniuBlockUploadDelegate>
{
    // upload info
    NSString *_bucket;
    NSString *_key;
    NSString *_host;
    NSDictionary *_extraParams;
    
    // file info
    NSString *_filePath;
    long long _fileSize;
    NSData *_mappedFile;
    
    // block upload concurrent control
    NSOperationQueue *_taskQueue;
    int _completedBlockCount;
    
    // block upload status
    int _blockCount;
    long long _totalBytesSent;
    NSMutableArray *_blockSentBytes;  // for updating progress
    NSMutableArray *_blockCtxs;       // for mkfile
}

@property (copy) NSString *token;
@property (assign) id<QiniuUploadDelegate> delegate;

+ (id) instanceWithToken:(NSString *)token;

- (id)initWithToken:(NSString *)token;

- (void) uploadFile:(NSString *)filePath
                key:(NSString *)key
             bucket:(NSString *)bucket
        extraParams:(NSDictionary *)extraParams;

@end
