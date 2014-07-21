//
//  QiniuSimpleUploader.h
//  QiniuSimpleUploader
//
//  Created by Qiniu Developers 2013
//

#import <Foundation/Foundation.h>
#import "QiniuHttpClient.h"
#import "QiniuUploadDelegate.h"

@class QiniuPutExtra;

// Upload local file to Qiniu Cloud Service with one single request.
@interface QiniuSimpleUploader : NSObject

// Delegates to receive events for upload progress info.
@property (assign, nonatomic) id<QiniuUploadDelegate> delegate;

// Token contains expiration field.
// It is possible that after a period you'll receive a 401 error with this token.
// If that happens you'll need to retrieve a new token from server and set here.
@property (copy, nonatomic) NSString *token;

// Returns a QiniuSimpleUploader instance.
+ (id) uploaderWithToken:(NSString *)token;

- (id)initWithToken:(NSString *)token;

// Upload local file to qiniu cloud storage, the extra is optional.
- (void) uploadFile:(NSString *)filePath
                key:(NSString *)key
              extra:(QiniuPutExtra *)extra;

- (void) uploadFileData:(NSData *)fileData
                    key:(NSString *)key
                  extra:(QiniuPutExtra *)extra;

@end

