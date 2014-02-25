//
//  QiniuResumableUploader.m
//  QiniuSDK
//
//  Created by ltz on 14-2-23.
//  Copyright (c) 2014年 Qiniu. All rights reserved.
//

#import "QiniuResumableUploader.h"
#import "QiniuResumableClient.h"

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
              extra:(QiniuResumableExtra *)extra
{
    NSError *error = nil;
    NSDictionary *fileAttr = [[NSFileManager defaultManager] attributesOfItemAtPath:filePath error:&error];
    if (error != nil) {
        [self.delegate uploadFailed:filePath error:error];
        return;
    }
    
    NSNumber *fileSizeNumber = [fileAttr objectForKey:NSFileSize];
    unsigned long long fileSize = [fileSizeNumber intValue];
    UInt32 blockCount = [QiniuResumableUploader blockCount:fileSize];
    
    
    if (extra == nil) {
        extra = [[QiniuResumableExtra alloc] initWithBlockCount:blockCount];
    }
    
    UInt32 blockSize = 1 << QiniuBlockBits;
    QiniuResumableClient *client = [[QiniuResumableClient alloc] initWithToken:self.token];

    if (extra.progresses == nil) {
        // it's a new extra
        extra.chunkCount = (fileSize / QiniuDefaultChunkSize) + (fileSize % QiniuDefaultChunkSize?1:0);
        
        extra.blockCount = blockCount;
        extra.progresses = [[NSMutableArray alloc] initWithCapacity:blockCount];
        for (int i=0; i<blockCount; i++) {
            [extra.progresses addObject:[NSNull null]];
        }
    } else if ([extra.progresses count] != blockCount) {
        error = [[NSError alloc] initWithDomain:@"invalid put progress" code:-1 userInfo:nil];
        [self.delegate uploadFailed:filePath error:error];
    } else {
        // drop uploaded chunks, resolve blocks
        extra.chunkCount = extra.uploadedBlockNumber * (blockSize / client.chunkSize);
    }
    
    
    for (int blockIndex=0; blockIndex<blockCount; blockIndex++) {
        
        QNCompleteBlock __block blockComplete = ^(AFHTTPRequestOperation *operation, NSError *error)
        {
            if (error != Nil) {
                [self.delegate uploadFailed:filePath error:error];
                return;
            }
            
            // operation == nil: block already in progresses
            if (operation != nil) {
                NSString *ctx = [operation.responseObject valueForKey:@"ctx"];
                [extra.progresses replaceObjectAtIndex:blockIndex withObject:ctx];
            }
            
            BOOL blockUploadedOK = [extra blockUploadedAndCheck];
            if (blockUploadedOK) {
                [client mkfile:key
                      fileSize:fileSize
                         extra:extra
                      progress:nil
                      complete:^(AFHTTPRequestOperation *operation, NSError *error) {
                          if (error) {
                              [self.delegate uploadFailed:filePath error:error];
                          }else{
                              NSDictionary *resp = operation.responseObject;
                              [self.delegate uploadSucceeded:filePath ret:resp];
                          }
                      }];
                return;
            }
        };

        if (extra.progresses[blockIndex] != [NSNull null]) {
            // block already uploaded
            blockComplete(nil, nil);
            continue;
        }
        
        UInt32 blockSize1 = blockSize;
        UInt32 offbase = blockIndex << QiniuBlockBits;
        if (blockIndex == blockCount - 1) {
            blockSize1 = fileSize - offbase;
        }
        
        NSFileHandle *fileHandle = [NSFileHandle fileHandleForReadingAtPath:filePath];
        [fileHandle seekToFileOffset:offbase];
        [client blockPut:fileHandle
              blockIndex:blockIndex
               blockSize:blockSize1
                   extra:extra
                progress:^(float percent) {
                    [self.delegate uploadProgressUpdated:filePath percent:percent];
                }
                complete:blockComplete];
    }
    
}

+ (UInt32) blockCount:(unsigned long long)fileSize
{
    return (UInt32)((fileSize + QiniuBlockMask) >> QiniuBlockBits);
}

@end
