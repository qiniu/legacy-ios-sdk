//
//  QiniuUtils.m
//  QiniuSDK
//
//  Created by Qiniu Developers 2013
//

#import "QiniuUtils.h"

#define kQiniuErrorKey     @"error"
#define kQiniuErrorDomain  @"QiniuErrorDomain"

NSError *qiniuError(int errorCode, NSString *errorDescription) {
    return [NSError errorWithDomain:kQiniuErrorDomain code:errorCode userInfo:[NSDictionary dictionaryWithObject:errorDescription forKey:kQiniuErrorKey]];
}

NSError *qiniuErrorWithRequest(AFHTTPRequestOperation *request) {
    NSDictionary *dic = nil;
    NSError *httpError = nil;
    long errorCode = 400;

    if (request) {
        NSDictionary *responseObj = request.responseObject;
        if ([responseObj isKindOfClass:NSDictionary.class]) {
            dic = responseObj;
        }
        httpError = [request error];
        errorCode = [request response].statusCode;
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

    NSString *reqid = [[request.response allHeaderFields] objectForKey:@"X-Reqid"];
    NSMutableDictionary *userInfo = [NSMutableDictionary dictionaryWithObject:reqid forKey:@"reqid"];
    if (errorDescription) {
        [userInfo setObject:errorDescription forKey:kQiniuErrorKey];
    }

    return [NSError errorWithDomain:kQiniuErrorDomain code:errorCode userInfo:userInfo];
}
