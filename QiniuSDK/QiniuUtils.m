//
//  QiniuUtils.m
//  QiniuSDK
//
//  Created by Qiniu Developers 2013
//

#import <UIKit/UIKit.h>

#import "QiniuUtils.h"
#import "QiniuConfig.h"

#define kQiniuErrorKey     @"error"
#define kQiniuErrorDomain  @"QiniuErrorDomain"

NSError *qiniuError(int errorCode, NSString *errorDescription) {
    return [NSError errorWithDomain:kQiniuErrorDomain code:errorCode userInfo:[NSDictionary dictionaryWithObject:errorDescription forKey:kQiniuErrorKey]];
}

NSError *qiniuErrorWithResponse(NSHTTPURLResponse *response, NSJSONSerialization *detail, NSError *err0) {
    
    if (response == nil) {
        return err0;
    }
    
    NSMutableDictionary *userInfo = nil;
    NSInteger errorCode = -1;
    
    if ([detail isKindOfClass:NSDictionary.class]) {
        userInfo = [NSMutableDictionary dictionaryWithDictionary:(NSDictionary *)detail];
    }
    errorCode = [response statusCode];
    
    if (!userInfo) {
        userInfo = [[NSMutableDictionary alloc] init];
    }
    
    NSString *reqid = [[response allHeaderFields] objectForKey:@"X-Reqid"];
    [userInfo setObject:reqid forKey:@"reqid"];
    
    return [NSError errorWithDomain:kQiniuErrorDomain code:errorCode userInfo:userInfo];
}

NSString *qiniuUserAgent() {
    return  [NSString stringWithFormat:@"Qiniu-iOS/%@ (%@; iOS %@; )", kQiniuVersion, [[UIDevice currentDevice] model], [[UIDevice currentDevice] systemVersion]];
}

BOOL isRetryHost(AFHTTPRequestOperation *operation) {
    
    NSInteger errorCode = [operation.response statusCode];
    
    if (errorCode / 100 == 4 || errorCode / 100 == 6 || errorCode / 100 == 7) {
        return false;
    }
    if (errorCode == 579 || errorCode == 599) {
        return false;
    }
    return true;
}

