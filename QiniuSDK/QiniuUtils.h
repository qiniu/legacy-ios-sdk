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

NSString *urlSafeBase64String(NSString *sourceString);

NSError *qiniuError(int errorCode, NSString *errorDescription);

NSError *qiniuErrorWithOperation(AFHTTPRequestOperation *operation, NSError *error);

NSString *qiniuUserAgent();

BOOL isRetryHost(AFHTTPRequestOperation *operation);
