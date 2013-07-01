//
//  QiniuUtils.m
//  QiniuSDK
//
//  Created by Qiniu Developers 2013
//

#import "QiniuUtils.h"
#import "GTMBase64.h"
#import "JSONKit.h"

#define kQiniuErrorKey     @"error"
#define kQiniuErrorDomain  @"QiniuErrorDomain"

NSError *qiniuError(int errorCode, NSString *errorDescription) {
    return [NSError errorWithDomain:kQiniuErrorDomain code:errorCode userInfo:[NSDictionary dictionaryWithObject:errorDescription forKey:kQiniuErrorKey]];
}

NSError *qiniuErrorWithRequest(ASIHTTPRequest *request) {
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
        NSObject *errorObj = [dic objectForKey:kQiniuErrorKey];
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
        userInfo = [NSDictionary dictionaryWithObject:errorDescription forKey:kQiniuErrorKey];
    }
    
    return [NSError errorWithDomain:kQiniuErrorDomain code:errorCode userInfo:userInfo];
}
