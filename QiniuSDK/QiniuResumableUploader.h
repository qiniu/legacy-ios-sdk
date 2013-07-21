//
//  QiniuResumableUpload.h
//  QiniuResumableUpload
//
//  Created by Qiniu Developers 2013
//

#import <Foundation/Foundation.h>
#import "QiniuBlockUploadDelegate.h"
#import "QiniuUploadDelegate.h"
#import "QiniuRioPutExtra.h"

@interface QiniuResumableUploader : NSObject<QiniuBlockUploadDelegate>
{
    // upload info
    NSString *_bucket;
    NSString *_key;
    QiniuRioPutExtra *_params;
    
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
             params:(QiniuRioPutExtra *)params;

@end
