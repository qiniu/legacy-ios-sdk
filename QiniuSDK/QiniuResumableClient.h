//
//  QiniuResumableClient.h
//  QiniuSDK
//
//  Created by ltz on 14-2-24.
//  Copyright (c) 2014年 Qiniu. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "AFNetwork2/AFNetworking.h"
#import "QiniuBlkputRet.h"

typedef void (^QNProgressBlock)(float);
typedef void (^QNCompleteBlock)(id object, NSError *error);

#define QiniuBlockBits 22
#define QiniuBlockMask ((1 << QiniuBlockBits) - 1)
#define QiniuDefaultChunkSize (256 * 1024)
#define QiniuDefaultMaxWorkers 3
#define QiniuDefaultTryTimes 3

@class QiniuRioPutExtra;

@interface QiniuResumableClient : AFHTTPRequestOperationManager

- (void)mkblock:(NSData *)mappedData
     offsetBase:(UInt32)offsetBase
      blockSize:(UInt32)blockSize
     bodyLength:(UInt32)bodyLength
       progress:(QNProgressBlock)progressBlock
       complete:(QNCompleteBlock)complete;

- (void)chunkPut:(NSData *)mappedData
     blockPutRet:(QiniuBlkputRet *)blockPutRet
      offsetBase:(UInt32)offsetBase
      bodyLength:(UInt32)bodyLength
        progress:(QNProgressBlock)progressBlock
        complete:(QNCompleteBlock)complete;

- (void)blockPut:(NSData *)mappedData
      blockIndex:(UInt32)blockIndex
       blockSize:(UInt32)blockSize
           extra:(QiniuRioPutExtra *)extra
        progress:(QNProgressBlock)progressBlock
        complete:(QNCompleteBlock)complete;

- (void)mkfile:(NSString *)key
      fileSize:(UInt32)fileSize
         extra:(QiniuRioPutExtra *)extra
      progress:(QNProgressBlock)progressBlock
      complete:(QNCompleteBlock)complete;

- (QiniuResumableClient *)initWithToken:(NSString *)token
                         withMaxWorkers:(UInt32)maxWorkers
                          withChunkSize:(UInt32)chunkSize
                            withTryTime:(UInt32)tryTime;

- (void)setHeaders:(NSMutableURLRequest *)request;

@property BOOL canceled;
- (void)cancelTasks;

@property UInt32 retryTime;
@property UInt32 chunkSize;
@property (copy, nonatomic) NSString *token;

@end

typedef void (^QiniuRioNotify)(int blockIndex, int blockSize, QiniuBlkputRet* ret);
typedef void (^QiniuRioNotifyErr)(int blockIndex, int blockSize, NSError* error);



@interface QiniuRioPutExtra : NSObject

+ (QiniuRioPutExtra *)extraWithParams:(NSDictionary *)params;
- (QiniuRioPutExtra *)init;
- (QiniuRioPutExtra *)initWithBlockCount:(UInt32)blockCount;

@property (retain, nonatomic)QiniuResumableClient *client;
- (void)cancelTasks;

@property (copy, nonatomic) NSDictionary* params;
@property (copy, nonatomic) NSString* mimeType;
@property UInt32 chunkSize;
@property UInt32 tryTimes;
@property UInt32 concurrentNum;
@property (retain, nonatomic) NSMutableArray* progresses;
@property (copy) QiniuRioNotify notify;
@property (copy) QiniuRioNotifyErr notifyErr;

@property UInt32 uploadedBlockNumber;
@property UInt32 blockCount;
- (BOOL)blockUploadedAndCheck;

@property UInt32 uploadedChunkNumber;
@property UInt32 chunkCount;
- (float)chunkUploadedAndPercent;

@end