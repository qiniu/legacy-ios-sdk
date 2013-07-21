//
//  QiniuUtils.h
//  QiniuSDK
//
//  Created by Qiniu Developers 2013
//

#import <Foundation/Foundation.h>
#import "ASIHTTPRequest.h"

NSString *urlsafeBase64String(NSString *sourceString);
NSError *qiniuNewError(int errorCode, NSString *errorDescription);
NSError *qiniuNewErrorWithRequest(ASIHTTPRequest *request);