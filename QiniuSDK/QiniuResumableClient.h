//
//  QiniuResumableClient.h
//  QiniuSDK
//
//  Created by ltz on 14-2-24.
//  Copyright (c) 2014年 Qiniu. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "AFNetwork2/AFNetworking.h"
typedef void (^QNProgressBlock)(float);
typedef void (^QNCompleteBlock)(id object, NSError *error);

#define QiniuBlockBits 22
#define QiniuBlockMask ((1 << QiniuBlockBits) - 1)
#define QiniuDefaultChunkSize (256 * 1024)

@class QiniuBlockPutRet;
@class QiniuResumableExtra;

@interface QiniuResumableClient : AFHTTPRequestOperationManager

- (void)mkblock:(NSFileHandle *)fileHandle
      blockSize:(UInt32)blockSize
     bodyLength:(UInt32)bodyLength
       progress:(QNProgressBlock)progressBlock
       complete:(QNCompleteBlock)complete;

- (void)chunkPut:(NSFileHandle *)fileHandle
     blockPutRet:(QiniuBlockPutRet *)blockPutRet
      bodyLength:(UInt32)bodyLength
        progress:(QNProgressBlock)progressBlock
        complete:(QNCompleteBlock)complete;

- (void)blockPut:(NSFileHandle *)fileHandle
      blockIndex:(UInt32)blockIndex
       blockSize:(UInt32)blockSize
           extra:(QiniuResumableExtra *)extra
        progress:(QNProgressBlock)progressBlock
        complete:(QNCompleteBlock)complete;

- (void)mkfile:(NSString *)key
      fileSize:(UInt32)fileSize
         extra:(QiniuResumableExtra *)extra
      progress:(QNProgressBlock)progressBlock
      complete:(QNCompleteBlock)complete;

- (QiniuResumableClient *)initWithToken:(NSString *)token;
- (void)setHeaders:(NSMutableURLRequest *)request;

@property UInt32 retryTime;
@property UInt32 chunkSize;
@property (copy, nonatomic) NSString *token;

@end

@interface QiniuBlockPutRet : NSObject

- (QiniuBlockPutRet *)initWithDictionary:(NSDictionary *)dictionary;

@property (copy, nonatomic) NSString *ctx;
@property UInt32 crc32;
@property UInt32 offset;
@property (copy, nonatomic) NSString *upHost;

@end

@interface QiniuResumableExtra : NSObject

+ (QiniuResumableExtra *)extraWithParams:(NSDictionary *)params;
- (QiniuResumableExtra *)init;
- (QiniuResumableExtra *)initWithBlockCount:(UInt32)blockCount;

@property (retain, nonatomic) NSDictionary *params;
@property (copy, nonatomic) NSString *mimeType;

@property (retain, nonatomic) NSMutableArray *progresses;

@property UInt32 uploadedBlockNumber;
@property UInt32 blockCount;
- (BOOL)blockUploadedAndCheck;

@property UInt32 uploadedChunkNumber;
@property UInt32 chunkCount;
- (float)chunkUploadedAndPercent;

@end
