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
{
    self = [super init];
    self.token = [[NSString alloc] initWithFormat:@"UpToken %@", token];
    self.retryTime = 3;
    self.chunkSize = QiniuDefaultChunkSize; // 256k
    
    self.responseSerializer = [AFJSONResponseSerializer serializer];
    self.operationQueue = [[NSOperationQueue alloc] init];
    [self.operationQueue setMaxConcurrentOperationCount:2];
    
    return self;
}

- (void)mkblock:(NSFileHandle *)fileHandle
      blockSize:(UInt32)blockSize
     bodyLength:(UInt32)bodyLength
       progress:(QNProgressBlock)progressBlock
       complete:(QNCompleteBlock)complete
{
   // NSMutableURLRequest *request = [[NSMutableURLRequest alloc] init];
    
    NSString *callUrl = [[NSString alloc] initWithFormat:@"%@/mkblk/%d", kQiniuUpHost, (unsigned int)blockSize];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:callUrl]];

    [self setHeaders:request];
    
    NSMutableData *postData = [NSMutableData data];
    [postData appendData:[fileHandle readDataOfLength:bodyLength]];
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

- (void)chunkPut:(NSFileHandle *)fileHandle
     blockPutRet:(QiniuBlockPutRet *)blockPutRet
      bodyLength:(UInt32)bodyLength
        progress:(QNProgressBlock)progressBlock
        complete:(QNCompleteBlock)complete
{

    NSString *callUrl = [[NSString alloc] initWithFormat:@"%@/bput/%@/%d", blockPutRet.upHost, blockPutRet.ctx, (unsigned int)blockPutRet.offset];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:callUrl]];
    
    [self setHeaders:request];
    
    NSMutableData *postData = [NSMutableData data];
    [postData appendData:[fileHandle readDataOfLength:bodyLength]];
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

- (void)blockPut:(NSFileHandle *)fileHandle
      blockIndex:(UInt32)blockIndex
       blockSize:(UInt32)blockSize
           extra:(QiniuResumableExtra *)extra
        progress:(QNProgressBlock)progressBlock
        complete:(QNCompleteBlock)complete
{
    UInt32 offsetBase = blockIndex << QiniuBlockBits;
    
    __block UInt32 bodyLength = self.chunkSize < blockSize ? self.chunkSize : blockSize;
    __block QiniuBlockPutRet *blockPutRet;
    __block UInt32 retryTime = self.retryTime;
    __block BOOL isMkblock = YES;
    
    QNCompleteBlock __block chunkComplete = ^(AFHTTPRequestOperation *operation, NSError *error)
    {
        NSLog(@"chunkComplete: upload util: %llu", [fileHandle offsetInFile] - offsetBase);
        if (error != nil) {
            
            NSLog(@"blockPut error: %@", error);
            if (retryTime == 0 || isMkblock) {
                complete(operation, error);
                return;
            } else {
                retryTime --;
                [fileHandle seekToFileOffset:offsetBase+blockPutRet.offset];
            }
        } else {
            progressBlock([extra chunkUploadedAndPercent]);
            retryTime = self.retryTime;
            isMkblock = NO;
            blockPutRet = [[QiniuBlockPutRet alloc] initWithDictionary:operation.responseObject];
            
            UInt32 remainLength = blockSize - blockPutRet.offset;
            bodyLength = self.chunkSize < remainLength ? self.chunkSize : remainLength;
        }
        
        if (blockPutRet.offset == blockSize) {
            complete(operation, nil);
            return;
        }
        
        [self chunkPut:fileHandle
           blockPutRet:blockPutRet
            bodyLength:bodyLength
              progress:progressBlock
              complete:chunkComplete];
    };
    
    [self mkblock:fileHandle
        blockSize:blockSize
       bodyLength:bodyLength
         progress:progressBlock
         complete:chunkComplete];
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
         extra:(QiniuResumableExtra *)extra
      progress:(QNProgressBlock)progressBlock
      complete:(QNCompleteBlock)complete
{
    
    NSString *mimeStr = extra.mimeType == nil ? @"" : [[NSString alloc] initWithFormat:@"/mimetype/%@", [QiniuResumableClient encode:extra.mimeType]];
    NSString *keyStr = [[NSString alloc] initWithFormat:@"/key/%@", [QiniuResumableClient encode:key]];
    NSLog(@"key: %@, keyStr: %@", key, keyStr);
    NSString *callUrl = [[NSString alloc] initWithFormat:@"%@/mkfile/%u%@%@", kQiniuUpHost, (unsigned int)fileSize, mimeStr, keyStr];
    
    if (extra.params != nil) {
        NSEnumerator *e = [extra.params keyEnumerator];
        for (id key = [e nextObject]; key != nil; key = [e nextObject]) {
            callUrl = [NSString stringWithFormat:@"%@/%@/%@", callUrl, key, [QiniuResumableClient encode:[extra.params objectForKey:key]]];
            NSLog(@"key: %@, obj: %@", key, [extra.params objectForKey:key]);
        }
    }
    NSLog(@"mkfile: %@", callUrl);
    
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


@implementation QiniuBlockPutRet
- (QiniuBlockPutRet *)initWithDictionary:(NSDictionary *)dictionary
{
    self = [super init];
    
    self.ctx = [dictionary valueForKey:@"ctx"];
    self.crc32 = [[dictionary valueForKey:@"crc32"] intValue];
    self.offset = [[dictionary valueForKey:@"offset"] intValue];
    self.upHost = [dictionary valueForKey:@"host"];
    
    return self;
}

@end

@implementation QiniuResumableExtra

+ (QiniuResumableExtra *)extraWithParams:(NSDictionary *)params
{
    QiniuResumableExtra *extra = [[QiniuResumableExtra alloc] init];
    extra.params = params;
    return extra;
}

- (QiniuResumableExtra *)init
{
    self = [super init];
    return self;
}

- (QiniuResumableExtra *)initWithBlockCount:(UInt32)count
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