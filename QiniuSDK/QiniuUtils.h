//
//  QiniuUtils.h
//  QiniuSDK
//
//  Created by Qiniu Developers on 13-3-9.
//  Copyright (c) 2013 Shanghai Qiniu Information Technologies Co., Ltd. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ASIHttpRequest/ASIHTTPRequest.h"

long long getFileSize(NSString *filePath);
int calcBlockCount(NSString *filePath);
NSString *urlsafeBase64String(NSString *sourceString);
NSString *urlParamsString(NSDictionary *dic);

NSError *prepareSimpleError(int errorCode, NSString *errorDescription);

NSError *prepareRequestError(ASIHTTPRequest *request);