//
//  QiniuUtils.m
//  QiniuSDK
//
//  Created by Qiniu Developers on 13-3-9.
//  Copyright (c) 2013 Shanghai Qiniu Information Technologies Co., Ltd. All rights reserved.
//

#import "QiniuUtils.h"
#import "QiniuConfig.h"
#import "GTMBase64/GTMBase64.h"
#import "JSONKit/JSONKit.h"

#define kErrorKey @"error"
#define kErrorDomain @"QiniuErrorDomain"

long long getFileSize(NSString *filePath)
{
    NSNumber* fileSizeNumber = [[[NSFileManager defaultManager] attributesOfItemAtPath:filePath error:nil] objectForKey:NSFileSize];
    
    return [fileSizeNumber longLongValue];
}

int calcBlockCount(NSString *filePath) {
    return ceil((double)getFileSize(filePath) / kBlockSize);
}

NSString *urlsafeBase64String(NSString *sourceString) {
    return [GTMBase64 stringByWebSafeEncodingData:[sourceString dataUsingEncoding:NSUTF8StringEncoding] padded:TRUE];
}

// Convert NSDictionary to strings like: key1=value1&key2=value2&key3=value3 ...
NSString *urlParamsString(NSDictionary *dic) {
    if (!dic) {
        return nil;
    }
    
    NSMutableString *callbackParamsStr = [NSMutableString string];
    for (NSString *key in [dic allKeys]) {
        if ([callbackParamsStr length] > 0) {
            [callbackParamsStr appendString:@"&"];
        }
        [callbackParamsStr appendFormat:@"%@=%@", key, [dic objectForKey:key]];
    }
    return callbackParamsStr;
}

NSError *prepareSimpleError(int errorCode, NSString *errorDescription) {
    
    return [NSError errorWithDomain:kErrorDomain code:errorCode userInfo:[NSDictionary dictionaryWithObject:errorDescription forKey:@"error"]];
}

NSError *prepareRequestError(ASIHTTPRequest *request) {
    NSDictionary *dic = nil;
    NSError *httpError = nil;
    int errorCode = 400;
    
    if (request) {
        NSString *responseString = [request responseString];
        if (responseString) {
            dic = [responseString objectFromJSONString];
        }
        httpError = [request error];
        errorCode = [request responseStatusCode];
    }
    
    NSString *errorDescription = nil;
    if (dic) { // Check if there is response content.
        NSObject *errorObj = [dic objectForKey:kErrorKey];
        if (errorObj) {
            errorDescription = (NSString *)errorObj;
        }
    }
    if (errorDescription == nil && httpError) { // No response, then try to retrieve the HTTP error info.
        errorCode = [httpError code];
        errorDescription = [httpError localizedDescription];
    }
    
    NSDictionary *userInfo = nil;
    if (errorDescription) {
        userInfo = [NSDictionary dictionaryWithObject:errorDescription forKey:kErrorKey];
    }
    
    return [NSError errorWithDomain:kErrorDomain code:errorCode userInfo:userInfo];
}
