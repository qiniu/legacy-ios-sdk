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

NSError *qiniuErrorWithOperation(AFHTTPRequestOperation *operation, NSError *error) {
    
    if (operation == nil || operation.responseObject == nil) {
        return error;
    }
    
    NSMutableDictionary *userInfo = nil;
    NSInteger errorCode = -1;
    
    if ([operation.responseObject isKindOfClass:NSDictionary.class]) {
        userInfo = [NSMutableDictionary dictionaryWithDictionary:operation.responseObject];
    }
    errorCode = [operation.response statusCode];
    
    if (!userInfo) {
        userInfo = [NSMutableDictionary init];
    }
    
    NSString *reqid = [[operation.response allHeaderFields] objectForKey:@"X-Reqid"];
    [userInfo setObject:reqid forKey:@"reqid"];
    
    return [NSError errorWithDomain:kQiniuErrorDomain code:errorCode userInfo:userInfo];
}
