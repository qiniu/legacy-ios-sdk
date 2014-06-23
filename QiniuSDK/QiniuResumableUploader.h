//
//  QiniuResumableUploader.h
//  QiniuSDK
//
//  Created by ltz on 14-2-23.
//  Copyright (c) 2014年 Qiniu. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "AFNetworking/AFNetworking.h"
#import "QiniuResumableClient.h"
#import "QiniuUploadDelegate.h"

@interface QiniuResumableUploader : NSObject

@property (assign, nonatomic) id<QiniuUploadDelegate> delegate;
@property (copy, nonatomic)NSString *token;


- (QiniuResumableUploader *)initWithToken:(NSString *)token;

- (void) uploadFile:(NSString *)filePath
                key:(NSString *)key
              extra:(QiniuRioPutExtra *)extra;

@property (retain, nonatomic)QiniuResumableClient *client;

@end

