//
//  QiniuUtils.h
//  QiniuSDK
//
//  Created by Qiniu Developers 2013
//

#import <Foundation/Foundation.h>
#import "AFHTTPRequestOperation.h"

typedef void (^QNProgress)(float percent);
typedef void (^QNComplete)(AFHTTPRequestOperation *operation, NSError *error);

NSError *qiniuError(int errorCode, NSString *errorDescription);

NSError *qiniuErrorWithResponse(NSHTTPURLResponse *response, NSJSONSerialization *detail, NSError *err0);

NSString *qiniuUserAgent();

BOOL isRetryHost(AFHTTPRequestOperation *operation);