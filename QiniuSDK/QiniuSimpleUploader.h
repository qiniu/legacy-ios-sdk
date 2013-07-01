//
//  QiniuSimpleUploader.h
//  QiniuSimpleUploader
//
//  Created by Qiniu Developers 2013
//

#import <Foundation/Foundation.h>
#import "QiniuUploadDelegate.h"
#import "QiniuPutExtra.h"
#import "ASIHttpRequest/ASIFormDataRequest.h"

// Upload local file to Qiniu Cloud Service with one single request.
@interface QiniuSimpleUploader : NSObject<ASIHTTPRequestDelegate, ASIProgressDelegate> {
@private
    NSString *_token;
    NSString *_filePath;
    long long _fileSize;
    long long _sentBytes;
    ASIFormDataRequest *_request;
}

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

@end
