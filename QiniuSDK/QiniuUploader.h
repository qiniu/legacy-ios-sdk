//
//  QiniuUploader.h
//  QiniuSDK
//
//  Created by Hugh Lv on 13-3-9.
//  Copyright (c) 2013年 Shanghai Qiniu Information Technologies Co., Ltd. All rights reserved.
//

#import <Foundation/Foundation.h>

// keys for extraParams field.
#define kMimeTypeKey @"mimeType"
#define kCrc32Key @"crc32"
#define kUserParams @"params"

@protocol QiniuUploader <NSObject>

@required

- (id)initWithToken:(NSString *)token;

// @brief Upload a local file.
//
// Before calling this function, you need to make sure the corresponding bucket has been created.
// You can make bucket on management console: https://portal.qiniu.com .
//
// Parameter extraParams is for extensibility purpose, it is optional.
// It could contain following key-value pair:
//      Key:mimeType Value:NSString *<Custom mimeType> -- E.g. "text/plain"
//          specify mimeType, or server side automatically determine the mimeType.
//      Key:crc32 Value:NSString *<CRC32> -- 10-digits CRC value.
//          specify file's crc32 value, server side will check it for file's integrity.
//      Key:params Value:NSDictionary *<User Custom Params>
//          Please refer to http://docs.qiniu.com/api/put.html#xVariables
- (void) uploadFile:(NSString *)filePath
                key:(NSString *)key
        extraParams:(NSDictionary *)extraParams;

@end
