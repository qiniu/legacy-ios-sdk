//
//  QiniuClient.h
//  QiniuSDK
//
//  Created by 张光宇 on 2/9/14.
//  Copyright (c) 2014 Shanghai Qiniu Information Technologies Co., Ltd. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "AFNetworking/AFNetworking.h"
typedef void (^QNBooleanResultBlock)(BOOL succeeded, NSError *error);
typedef void (^QNArrayResultBlock)(NSArray *result, NSError *error);
typedef void (^QNObjectResultBlock)(id object, NSError *error);
@class QiniuPutExtra;


#define QiniuClient [QiniuHttpClient manager]

@interface QiniuHttpClient : AFHTTPRequestOperationManager
- (AFHTTPRequestOperation *)uploadFile:(NSString *)filePath
                                   key:(NSString *)key
                                 token:(NSString *)token
                                 extra:(QiniuPutExtra *)extra
                              progress:(void (^)(float percent))progressBlock
                              complete:(QNObjectResultBlock)complete;
@end





@interface QiniuPutExtra : NSObject

// user comtom params, refer to http://docs.qiniu.com/api/put.html#xVariables
@property (retain, nonatomic) NSDictionary *params;

// specify file's mimeType, or server side automatically determine the mimeType.
@property (copy, nonatomic) NSString *mimeType;

// specify file's crc32 value.
// server side can check it for integrity accodring to the value of checkCrc.
@property UInt32 crc32;

// if checkCrc is 0, server side will not check crc32.
// if checkCrc is 1, server side will check crc32 using the value of crc32.
@property UInt32 checkCrc;

- (NSDictionary *)convertToPostParams;

@end
