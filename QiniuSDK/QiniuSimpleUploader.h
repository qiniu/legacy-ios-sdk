//
//  QiniuSimpleUploader.h
//  QiniuSimpleUploader
//
//  Created by Qiniu Developers on 12-11-14.
//  Copyright (c) 2012 Shanghai Qiniu Information Technologies Co., Ltd. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "QiniuUploadDelegate.h"
#import "ASIHTTPRequest/ASIFormDataRequest.h"

// Following are the legal keys for extraParams field.

#define kCallbackParamsKey @"callbackParams"
#define kCustomMetaKey @"customMeta"
#define kMimeTypeKey @"mimeType"

// Upload local file to Qiniu Cloud Service with one single request.
//
// This class is proper for uploading medium to small files (< 4MB)。
// 
@interface QiniuSimpleUploader : NSObject<ASIHTTPRequestDelegate, ASIProgressDelegate> {
@private
    NSString *_token;
    long long _sentBytes;
    ASIFormDataRequest *_request;
}

// @brief Token.
//
// NOTE: Token contains expiration field, so it is possible that after a period you'll receive a 401 error with this token.
// If that happens you'll need to retrieve a new token from server and set here.
@property (copy, nonatomic) NSString *token;

// Delegates to receive events for upload progress info.
@property (assign, nonatomic) id<QiniuUploadDelegate> delegate;

// Returns a QiniuSimpleUploader instance. Auto-released.
//
// If you want to keep the instance for more than one message cycle, please use retain.
//
+ (id) uploaderWithToken:(NSString *)token;

// @brief Upload a local file.
//
// Before calling this function, you need to make sure the corresponding bucket has been created.
// You can make bucket on management console: http://dev.qiniutek.com/ .
//
// Parameter extraParams is for extensibility purpose. It could contain following key-value pair:
//      Key:mimeType Value:NSString *<Custom mime type> -- E.g. "text/plain"
//          This is optional since server side can automatically determine the mime type. 
//      Key:customMeta Value:NSString *<Custom meta info> -- For notes purpose.
//          Please refer to http://docs.qiniutek.com/v3/api/words/#CustomMeta
//      Key:callbackParams Value:NSDictionary *<Callback Params>
//          Please refer to http://docs.qiniutek.com/v3/api/io/#callback-after-uploaded
//          To use this feature, you also need to retrieve a corresponding token with appropriate authpolicy.
- (void) upload:(NSString *)filePath
         bucket:(NSString *)bucket
            key:(NSString *)key
    extraParams:(NSDictionary *)extraParams;

@end
