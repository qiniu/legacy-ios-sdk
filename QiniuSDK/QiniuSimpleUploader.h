//
//  QiniuSimpleUploader.h
//  QiniuSimpleUploader
//
//  Created by Qiniu Developers 2013
//

#import <Foundation/Foundation.h>
#import "QiniuHttpClient.h"

// ------------------------------------------------------------------------------------

// Upload delegates. Should be implemented by callers to receive callback info.

@protocol QiniuUploadDelegate <NSObject>

@optional

// Progress updated. 1.0 indicates 100%.
- (void)uploadProgressUpdated:(NSString *)filePath percent:(float)percent;

// Following two methods are required, because without them caller won't know when the
// procedure is completed.

@required
// Upload completed successfully.
- (void)uploadSucceeded:(NSString *)filePath ret:(NSDictionary *)ret;

// Upload failed.
- (void)uploadFailed:(NSString *)filePath error:(NSError *)error;

@end


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

@end

