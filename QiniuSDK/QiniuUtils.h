//
//  QiniuUtils.h
//  QiniuSDK
//
//  Created by Qiniu Developers 2013
//

#import <Foundation/Foundation.h>
#import "AFHTTPRequestOperation.h"

NSError *qiniuError(int errorCode, NSString *errorDescription);

NSError *qiniuErrorWithResponse(NSHTTPURLResponse *response, NSJSONSerialization *detail, NSError *err0);
