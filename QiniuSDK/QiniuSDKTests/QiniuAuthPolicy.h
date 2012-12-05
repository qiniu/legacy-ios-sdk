//
//  QiniuAuthPolicy.h
//  QiniuSDK
//
//  Created by Qiniu Developers on 12-11-2.
//  Copyright (c) 2012 Shanghai Qiniu Information Technologies Co., Ltd. All rights reserved.
//

#import <Foundation/Foundation.h>

// NOTE: Generally speaking, this class is not required for client development.
// The token string should be retrieved from your biz server.

// Refer to the spec: http://docs.qiniutek.com/v3/api/io/#upload-token
@interface QiniuAuthPolicy : NSObject

@property (retain, nonatomic) NSString *scope;
@property (retain, nonatomic) NSString *callbackUrl;
@property (retain, nonatomic) NSString *callbackBodyType;
@property (retain, nonatomic) NSString *customer;
@property int expires;
@property int escape;

// Make uptoken string.
- (NSString *)makeToken:(NSString *)accessKey secretKey:(NSString *)secretKey;

@end
