//
//  QiniuBlockUpload.h
//  Hello Objective-C
//
//  Created by 时 嘉赟 on 6/29/13.
//  Copyright (c) 2013 时 嘉赟. All rights reserved.
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
