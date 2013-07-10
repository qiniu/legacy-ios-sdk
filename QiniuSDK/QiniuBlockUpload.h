//
//  QiniuBlockUpload.h
//  QiniuBlockUpload
//
//  Created by Qiniu Developers 2013
//

#import <Foundation/Foundation.h>
#import "QiniuBlockUploadDelegate.h"

@interface QiniuBlockUpload : NSOperation
{
    int _blockIndex;
    long long _blockSize;
    NSData *_blockData;
    NSString *_token;
    NSString *_host;
    NSString *_lastCtx;
    int _retryTimes;
}

@property (assign) id<QiniuBlockUploadDelegate> delegate;

+ (id)instanceWithToken:(NSString *)token blockIndex:(int)blockIndex blockData:(NSData *)blockData;

@end
