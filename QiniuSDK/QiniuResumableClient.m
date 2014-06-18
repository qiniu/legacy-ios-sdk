//
//  QiniuResumableClient.m
//  QiniuSDK
//
//  Created by ltz on 14-2-24.
//  Copyright (c) 2014年 Qiniu. All rights reserved.
//

#import "QiniuResumableClient.h"
#import "QiniuConfig.h"

@implementation QiniuResumableClient

- (QiniuResumableClient *)initWithToken:(NSString *)token
                         withMaxWorkers:(UInt32)maxWorkers
                          withChunkSize:(UInt32)chunkSize
                            withTryTime:(UInt32)tryTime
{
    self = [super init];
    self.token = [[NSString alloc] initWithFormat:@"UpToken %@", token];
    self.retryTime = tryTime;
    self.chunkSize = chunkSize; // 256k
    
    self.responseSerializer = [AFJSONResponseSerializer serializer];
    self.operationQueue = [[NSOperationQueue alloc] init];
    [self.operationQueue setMaxConcurrentOperationCount:maxWorkers];
    
    return self;
}

- (void)cancelTasks
{
    self.canceled = YES;
}

- (void)mkblock:(NSData *)mappedData
     offsetBase:(UInt32)offset
      blockSize:(UInt32)blockSize
     bodyLength:(UInt32)bodyLength
       progress:(QNProgressBlock)progressBlock
       complete:(QNCompleteBlock)complete
{
    if (self.canceled) {
        return;
    }
    NSString *callUrl = [[NSString alloc] initWithFormat:@"%@/mkblk/%d", kQiniuUpHost, (unsigned int)blockSize];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:callUrl]];

    [self setHeaders:request];
    
    NSData *postData = [mappedData subdataWithRange:NSMakeRange(offset, bodyLength)];
    [request setHTTPBody:postData];
    
    QNCompleteBlock success = ^(AFHTTPRequestOperation *operation, id responseObject)
    {
        // TODO: check crc32
        complete(operation, nil);
    };
    QNCompleteBlock failure = ^(AFHTTPRequestOperation *operation, NSError *error)
    {
        complete(operation, error);
    };
    
    AFHTTPRequestOperation *operation = [super HTTPRequestOperationWithRequest:request
                                                                      success:success
                                                                      failure:failure];
    [self.operationQueue addOperation:operation];
}

- (void)chunkPut:(NSData *)mappedData
     blockPutRet:(QiniuBlkputRet *)blockPutRet
      offsetBase:(UInt32)offsetBase
      bodyLength:(UInt32)bodyLength
        progress:(QNProgressBlock)progressBlock
        complete:(QNCompleteBlock)complete
{
    if (self.canceled) {
        return;
    }
    NSString *callUrl = [[NSString alloc] initWithFormat:@"%@/bput/%@/%d", blockPutRet.host, blockPutRet.ctx, (unsigned int)blockPutRet.offset];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:callUrl]];
    
    [self setHeaders:request];
    
    NSData *postData = [mappedData subdataWithRange:NSMakeRange(offsetBase + blockPutRet.offset, bodyLength)];
    [request setHTTPBody:postData];
    
    QNCompleteBlock success = ^(AFHTTPRequestOperation *operation, id responseObject)
    {
        // TODO: check crc32
        complete(operation, nil);
    };
    QNCompleteBlock failure = ^(AFHTTPRequestOperation *operation, NSError *error)
    {
        complete(operation, error);
    };
    
    AFHTTPRequestOperation *operation = [super HTTPRequestOperationWithRequest:request
                                                                      success:success
                                                                      failure:failure];
    [self.operationQueue addOperation:operation];
}

- (void)blockPut:(NSData *)mappedData
      blockIndex:(UInt32)blockIndex
       blockSize:(UInt32)blockSize
           extra:(QiniuRioPutExtra *)extra
        progress:(QNProgressBlock)progressBlock
        complete:(QNCompleteBlock)complete
{
  //  @autoreleasepool {
        
    
    UInt32 offsetBase = blockIndex << QiniuBlockBits;
    
    __block UInt32 bodyLength = self.chunkSize < blockSize ? self.chunkSize : blockSize;
    __block QiniuBlkputRet *blockPutRet;
    __block UInt32 retryTime = self.retryTime;
    __block BOOL isMkblock = YES;
    
    QNCompleteBlock __block __weak weakChunkComplete;
    QNCompleteBlock chunkComplete;
    weakChunkComplete = chunkComplete = ^(AFHTTPRequestOperation *operation, NSError *error)
    {
        if (error != nil) {
            
            if (retryTime == 0 || isMkblock || [operation.response statusCode] == 701) {
                complete(operation, error);
                return;
            } else {
                retryTime --;
            }
        } else {
            if (progressBlock != nil) {
                progressBlock([extra chunkUploadedAndPercent]);
            }
            retryTime = self.retryTime;
            isMkblock = NO;
            blockPutRet = [[QiniuBlkputRet alloc] initWithDictionary:operation.responseObject];
            
            UInt32 remainLength = blockSize - blockPutRet.offset;
            bodyLength = self.chunkSize < remainLength ? self.chunkSize : remainLength;
        }
        
        if (blockPutRet.offset == blockSize) {
            complete(operation, nil);
            return;
        }
        
        [self chunkPut:mappedData
           blockPutRet:blockPutRet
            offsetBase:offsetBase
            bodyLength:bodyLength
              progress:progressBlock
              complete:weakChunkComplete];
    };
    
    [self mkblock:mappedData
       offsetBase:offsetBase
        blockSize:blockSize
       bodyLength:bodyLength
         progress:progressBlock
         complete:chunkComplete];
//    }
}

+ (NSString *)encode:(NSString *)str
{
    str = [[str dataUsingEncoding:NSUTF8StringEncoding] base64EncodedStringWithOptions:0];
    
    // is there other methed?
    str = [str stringByReplacingOccurrencesOfString:@"+" withString:@"-"];
    str = [str stringByReplacingOccurrencesOfString:@"/" withString:@"_"];
    return str;
}

- (void)mkfile:(NSString *)key
      fileSize:(UInt32)fileSize
         extra:(QiniuRioPutExtra *)extra
      progress:(QNProgressBlock)progressBlock
      complete:(QNCompleteBlock)complete
{
    
    NSString *mimeStr = extra.mimeType == nil ? @"" : [[NSString alloc] initWithFormat:@"/mimetype/%@", [QiniuResumableClient encode:extra.mimeType]];
    
    NSString *callUrl = [[NSString alloc] initWithFormat:@"%@/mkfile/%u%@", kQiniuUpHost, (unsigned int)fileSize, mimeStr];
    
    if (key != nil) {
        NSString *keyStr = [[NSString alloc] initWithFormat:@"/key/%@", [QiniuResumableClient encode:key]];
        callUrl = [NSString stringWithFormat:@"%@%@", callUrl, keyStr];
    }
    
    if (extra.params != nil) {
        NSEnumerator *e = [extra.params keyEnumerator];
        for (id key = [e nextObject]; key != nil; key = [e nextObject]) {
            callUrl = [NSString stringWithFormat:@"%@/%@/%@", callUrl, key, [QiniuResumableClient encode:[extra.params objectForKey:key]]];
        }
    }
    
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:[[NSURL alloc] initWithString:callUrl]];
    [self setHeaders:request];
    
    NSMutableData *postData = [NSMutableData data];
    NSString *bodyStr = [extra.progresses componentsJoinedByString:@","];
    [postData appendData:[bodyStr dataUsingEncoding:NSUTF8StringEncoding]];
    [request setHTTPBody:postData];
    
    QNCompleteBlock success = ^(AFHTTPRequestOperation *operation, id responseObject)
    {
        complete(operation, nil);
    };
    QNCompleteBlock failure = ^(AFHTTPRequestOperation *operation, NSError *error)
    {
        complete(operation, error);
    };
    
    AFHTTPRequestOperation *operation = [self HTTPRequestOperationWithRequest:request
                                                                      success:success
                                                                      failure:failure];
    [self.operationQueue addOperation:operation];
}

- (void)setHeaders:(NSMutableURLRequest *)request
{
    [request setValue:self.token forHTTPHeaderField:@"Authorization"];
    [request setValue:@"application/octet-stream" forHTTPHeaderField:@"Content-Type"];
    [request addValue:kQiniuUserAgent forHTTPHeaderField:@"User-Agent"];
    [request setHTTPMethod:@"POST"];
}

@end

@implementation QiniuRioPutExtra

+ (QiniuRioPutExtra *)extraWithParams:(NSDictionary *)params
{
    QiniuRioPutExtra *extra = [[QiniuRioPutExtra alloc] init];
    extra.params = params;
    return extra;
}

- (QiniuRioPutExtra *)init
{
    self = [super init];
    return self;
}

- (void)cancelTasks
{
    [self.client cancelTasks];
}

- (QiniuRioPutExtra *)initWithBlockCount:(UInt32)count
{
    self = [super init];
    self.blockCount = count;
    return self;
}

- (BOOL) blockUploadedAndCheck
{
    static NSLock *blockNumlock;
    if (blockNumlock == nil) {
        blockNumlock = [[NSLock alloc] init];
    }
    
    BOOL allBlockOk;
    
    [blockNumlock lock];
    self.uploadedBlockNumber ++;
    allBlockOk = self.uploadedBlockNumber == self.blockCount;
    [blockNumlock unlock];
    
    return allBlockOk;
}

- (float) chunkUploadedAndPercent
{
    static NSLock *chunkNumlock;
    if (chunkNumlock == nil) {
        chunkNumlock = [[NSLock alloc] init];
    }
    
    float percent;
    [chunkNumlock lock];
    self.uploadedChunkNumber ++;
    percent = (float)self.uploadedChunkNumber / self.chunkCount;
    [chunkNumlock unlock];
    
    return percent;
}

@end
