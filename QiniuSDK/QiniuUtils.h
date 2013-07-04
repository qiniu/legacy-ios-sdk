//
//  QiniuUtils.h
//  QiniuSDK
//
//  Created by Qiniu Developers 2013
//

#import <Foundation/Foundation.h>
#import "ASIHTTPRequest.h"

NSError *qiniuError(int errorCode, NSString *errorDescription);

NSError *qiniuErrorWithRequest(ASIHTTPRequest *request);