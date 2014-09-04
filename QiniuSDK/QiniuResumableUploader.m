//
//  QiniuResumableUploader.m
//  QiniuSDK
//
//  Created by ltz on 14-2-23.
//  Copyright (c) 2014年 Qiniu. All rights reserved.
//

#import "QiniuResumableUploader.h"
#import "QiniuResumableClient.h"
#import "QiniuUtils.h"
#import "QiniuConfig.h"

@implementation QiniuResumableUploader

- (QiniuResumableUploader *) initWithToken:(NSString *)token
{
    if (self = [super init]) {
        self.token = token;
    }
    return self;
}

- (void) uploadFile:(NSString *)filePath
                key:(NSString *)key
              extra:(QiniuRioPutExtra *)extra
{        
    @autoreleasepool {
        NSError *error = nil;
        NSDictionary *fileAttr = [[NSFileManager defaultManager] attributesOfItemAtPath:filePath error:&error];
        if (error != nil) {
            [self.delegate uploadFailed:filePath error:error];
            return;
        }
        
        NSNumber *fileSizeNumber = [fileAttr objectForKey:NSFileSize];
        UInt32 fileSize = [fileSizeNumber intValue];
        UInt32 blockCount = [QiniuResumableUploader blockCount:fileSize];
        
        
        if (extra == nil) {
            extra = [[QiniuRioPutExtra alloc] initWithBlockCount:blockCount];
        }
        if (extra.concurrentNum == 0) {
            extra.concurrentNum = QiniuDefaultMaxWorkers;
        }
        if (extra.chunkSize == 0) {
            extra.chunkSize = QiniuDefaultChunkSize;
        }
        if (extra.tryTimes == 0) {
            extra.tryTimes = QiniuDefaultTryTimes;
        }
        
        
        UInt32 blockSize = 1 << QiniuBlockBits;
        
        if (extra.client == nil) {
            extra.client = [[QiniuResumableClient alloc] initWithToken:self.token
                                                        withMaxWorkers:extra.concurrentNum
                                                         withChunkSize:extra.chunkSize
                                                           withTryTime:extra.tryTimes];
        }
        extra.client.canceled = NO;
        extra.uploadedBlockNumber = 0;
        extra.uploadedChunkNumber = 0;
        
        
        if (extra.progresses == nil) {
            // it's a new extra
            extra.chunkCount = (fileSize / extra.chunkSize) + (fileSize % extra.chunkSize?1:0);
            
            extra.blockCount = blockCount;
            extra.progresses = [[NSMutableArray alloc] initWithCapacity:blockCount];
            for (int i=0; i<blockCount; i++) {
                [extra.progresses addObject:[NSNull null]];
            }
        } else if ([extra.progresses count] != blockCount) {
            error = [[NSError alloc] initWithDomain:@"invalid put progress" code:-1 userInfo:nil];
            [self.delegate uploadFailed:filePath error:error];
            return;
        }
        
        
        NSData *mappedData = [NSData dataWithContentsOfFile:filePath options:NSDataReadingMappedIfSafe error:&error];
        if (error != nil) {
            [self.delegate uploadFailed:filePath error:error];
            return;
        }
        
        QNProgress __block progressBlock;
        QNProgress __block __weak weakProgressBlock = progressBlock = ^(float percent) {
            if ([self.delegate respondsToSelector:@selector(uploadProgressUpdated:percent:)]) {
                [self.delegate uploadProgressUpdated:filePath percent:percent];
            }
        };
        
        for (int blockIndex=0; blockIndex<blockCount; blockIndex++) {
            
            UInt32 offbase = blockIndex << QiniuBlockBits;
            int __block blockRetryIndex = 0;
            int __block mkfileRetryIndex = 0;
            __block UInt32 blockSize1;
            __block UInt32 retryTime = extra.client.retryTime;
            
            
            blockSize1 = blockSize;
            if (blockIndex == blockCount - 1) {
                blockSize1 = fileSize - offbase;
            }
            
            QNCompleteBlock __block __weak weakBlockComplete;
            QNCompleteBlock blockComplete;
            weakBlockComplete = blockComplete = ^(AFHTTPRequestOperation *operation, NSError *error)
            {
                
                /****
                 // for retry test
                 if (retryTime == client.retryTime) {
                 error = @"errxxx";
                 }
                 ****/
                
                if (error != nil) {
                    if (retryTime > 0) {
                        retryTime --;
                        
                        [extra.client blockPut:mappedData
                                    blockIndex:blockIndex
                                     blockSize:blockSize1
                                         extra:extra
                                        uphost:kQiniuUpHosts[blockRetryIndex]
                                      progress:weakProgressBlock
                                      complete:weakBlockComplete];
                    } else {
                        if (blockRetryIndex < kQiniuUpHostsLast && isRetryHost(operation)) {
                            blockRetryIndex ++;
                            retryTime = extra.client.retryTime;
                            
                            [extra.client blockPut:mappedData
                                        blockIndex:blockIndex
                                         blockSize:blockSize1
                                             extra:extra
                                            uphost:kQiniuUpHosts[blockRetryIndex]
                                          progress:weakProgressBlock
                                          complete:weakBlockComplete];
                            
                            return;

                        }
                        if (extra.notifyErr != nil) {
                            error = qiniuErrorWithOperation(operation, error);
                            extra.notifyErr(blockIndex, blockSize1, error);
                        }
                    }
                    return;
                }
                
                
                // operation == nil: block already in progresses
                if (operation != nil) {
                    NSString *ctx = [operation.responseObject valueForKey:@"ctx"];
                    [extra.progresses replaceObjectAtIndex:blockIndex withObject:ctx];
                    
                    QiniuBlkputRet *ret = [[QiniuBlkputRet alloc] initWithDictionary:operation.responseObject];
                    if (extra.notify != nil) {
                        extra.notify(blockIndex, blockSize1, ret);
                    }
                }
                
                BOOL blockUploadedOK = [extra blockUploadedAndCheck];
                if (blockUploadedOK) {
                    
                    QNCompleteBlock __block completeBlock;
                    QNCompleteBlock __block __weak weakCompleteBlock = completeBlock = ^(AFHTTPRequestOperation *operation, NSError *error) {
                        if (error) {
                            if (mkfileRetryIndex < kQiniuUpHostsLast && isRetryHost(operation)) {
                                
                                mkfileRetryIndex ++;
                                [extra.client mkfile:key
                                            fileSize:fileSize
                                               extra:extra
                                              uphost:kQiniuUpHosts[mkfileRetryIndex]
                                            progress:weakProgressBlock
                                            complete:weakCompleteBlock];
                                
                                return;
                            }
                            error = qiniuErrorWithOperation(operation, error);
                            [self.delegate uploadFailed:filePath error:error];
                        }else{
                            NSDictionary *resp = operation.responseObject;
                            [self.delegate uploadSucceeded:filePath ret:resp];
                        }
                    };
                    
                    [extra.client mkfile:key
                                fileSize:fileSize
                                   extra:extra
                                  uphost:kQiniuUpHosts[0]
                                progress:weakProgressBlock
                                complete:weakCompleteBlock];
                    return;
                }
            };

            
            if (extra.progresses[blockIndex] != [NSNull null]) {
                // block already uploaded
                int count = blockSize1 / extra.chunkSize + ((blockSize1%extra.chunkSize!=0)?1:0);
                NSLog(@"count: %d", count);
                extra.uploadedChunkNumber += count;
                
                weakBlockComplete(nil, nil);
                continue;
            }
            
            
            [extra.client blockPut:mappedData
                        blockIndex:blockIndex
                         blockSize:blockSize1
                             extra:extra
                            uphost:kQiniuUpHosts[0]
                          progress:weakProgressBlock
                          complete:weakBlockComplete];
        }
    }
}

+ (UInt32) blockCount:(unsigned long long)fileSize
{
    return (UInt32)((fileSize + QiniuBlockMask) >> QiniuBlockBits);
}

@end
