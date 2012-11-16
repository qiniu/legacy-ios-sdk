//
//  QiniuAuthPolicy.h
//  QiniuSDK
//
//  Created by Hugh Lv on 12-11-2.
//  Copyright (c) 2012年 Shanghai Qiniu Information Technologies Co., Ltd. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface QiniuAuthPolicy : NSObject {
	NSString *scope;
	NSString *callbackUrl;
	NSString *callbackBodyType;
    NSString *customer;
	int expires;
}

@property (retain, nonatomic) NSString *scope;
@property (retain, nonatomic) NSString *callbackUrl;
@property (retain, nonatomic) NSString *callbackBodyType;
@property (retain, nonatomic) NSString *customer;
@property int expires;

// Make uptoken string.
- (NSString *)makeToken:(NSString *)accessKey secretKey:(NSString *)secretKey;

// Marshal as JSON string.
- (NSString *)marshal;

@end
