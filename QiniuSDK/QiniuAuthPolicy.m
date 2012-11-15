//
//  QiniuAuthPolicy.m
//  QiniuSDK
//
//  Created by Hugh Lv on 12-11-2.
//  Copyright (c) 2012年 Shanghai Qiniu Information Technologies Co., Ltd. All rights reserved.
//

#import "QiniuAuthPolicy.h"
#import "SBJson/SBJson.h"
#import <CommonCrypto/CommonHMAC.h>
#import "GTMBase64/GTMBase64.h"

@implementation QiniuAuthPolicy

@synthesize scope;
@synthesize callbackUrl;
@synthesize callbackBodyType;
@synthesize customer;
@synthesize expires;

// Make a token string conform to the UpToken spec.

- (NSString *)makeToken:(NSString *)accessKey secretKey:(NSString *)secretKey
{
    const char *secretKeyStr = [secretKey cStringUsingEncoding:NSUTF8StringEncoding];
    
	NSString *policy = [self marshal];
    NSLog(@"Policy: %@", policy);
    
    
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
    //NSString *deadlineStr = [NSString stringWithFormat:@"%ld", deadline];
    NSNumber *deadlineNumber = [NSNumber numberWithLongLong:deadline];
    
    SBJsonWriter *writer = [[SBJsonWriter alloc] init];
    writer.sortKeys = FALSE;
    writer.humanReadable = FALSE;
    
    NSDictionary *jsonObject = [NSDictionary dictionaryWithObjectsAndKeys:self.scope, @"scope",
                               self.callbackUrl, @"callbackUrl",
                               self.callbackBodyType, @"callbackBodyType",
                               self.customer, @"customer",
                               deadlineNumber, @"deadline",
                               nil, nil];
    
    NSString *jsonStr = [writer stringWithObject:jsonObject];
    
    [writer release];
    
    return jsonStr;
}

@end
