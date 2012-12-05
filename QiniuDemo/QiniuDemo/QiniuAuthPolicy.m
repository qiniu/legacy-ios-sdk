//
//  QiniuAuthPolicy.m
//  QiniuSDK
//
//  Created by Qiniu Developers on 12-11-2.
//  Copyright (c) 2012 Shanghai Qiniu Information Technologies Co., Ltd. All rights reserved.
//

#import "QiniuAuthPolicy.h"
#import <CommonCrypto/CommonHMAC.h>
#import "../../QiniuSDK/GTMBase64/GTMBase64.h"
#import "../../QiniuSDK/JSONKit/JSONKit.h"

@implementation QiniuAuthPolicy

@synthesize scope;
@synthesize callbackUrl;
@synthesize callbackBodyType;
@synthesize customer;
@synthesize expires;
@synthesize escape;

// Make a token string conform to the UpToken spec.

- (NSString *)makeToken:(NSString *)accessKey secretKey:(NSString *)secretKey
{
    const char *secretKeyStr = [secretKey UTF8String];
    
	NSString *policy = [self marshal];
    
    NSData *policyData = [policy dataUsingEncoding:NSUTF8StringEncoding];
    
    NSString *encodedPolicy = [GTMBase64 stringByWebSafeEncodingData:policyData padded:TRUE];
    const char *encodedPolicyStr = [encodedPolicy cStringUsingEncoding:NSUTF8StringEncoding];
    
    char digestStr[CC_SHA1_DIGEST_LENGTH];
    bzero(digestStr, 0);
    
    CCHmac(kCCHmacAlgSHA1, secretKeyStr, strlen(secretKeyStr), encodedPolicyStr, strlen(encodedPolicyStr), digestStr);
    
    NSString *encodedDigest = [GTMBase64 stringByWebSafeEncodingBytes:digestStr length:CC_SHA1_DIGEST_LENGTH padded:TRUE];
    
    NSString *token = [NSString stringWithFormat:@"%@:%@:%@",  accessKey, encodedDigest, encodedPolicy];
    
	return token;
}

// Marshal as JSON format string.

- (NSString *)marshal
{
    time_t deadline;
    time(&deadline);
    
    deadline += (self.expires > 0) ? self.expires : 3600; // 1 hour by default.
    NSNumber *deadlineNumber = [NSNumber numberWithLongLong:deadline];

    NSMutableDictionary *dic = [NSMutableDictionary dictionary];
    
    if (self.scope) {
        [dic setObject:self.scope forKey:@"scope"];
    }
    if (self.callbackUrl) {
        [dic setObject:self.callbackUrl forKey:@"callbackUrl"];
    }
    if (self.callbackBodyType) {
        [dic setObject:self.callbackBodyType forKey:@"callbackBodyType"];
    }
    if (self.customer) {
        [dic setObject:self.customer forKey:@"customer"];
    }
    
    [dic setObject:deadlineNumber forKey:@"deadline"];
    
    if (self.escape) {
        NSNumber *escapeNumber = [NSNumber numberWithLongLong:escape];
        [dic setObject:escapeNumber forKey:@"escape"];
    }
    
    NSString *json = [dic JSONString];
    
    return json;
}

@end
