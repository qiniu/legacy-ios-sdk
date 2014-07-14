//
//  QiniuSimpleUploader.m
//  QiniuSimpleUploader
//
//  Created by Qiniu Developers 2013
//

#import "QiniuConfig.h"
#import "QiniuSimpleUploader.h"
#import "QiniuUtils.h"
#import "QiniuHttpClient.h"

@interface QiniuSimpleUploader ()
//@property(nonatomic,copy)NSString *filePath;
//@property(nonatomic,assign)uint64_t *fileSize;
//@property(nonatomic,assign)uint64_t *sentBytes;
@end

// ------------------------------------------------------------------------------------------

@implementation QiniuSimpleUploader

+ (id) uploaderWithToken:(NSString *)token {
    return [[self alloc] initWithToken:token];
}

// Must always override super's designated initializer.
- (id)init {
    return [self initWithToken:nil];
}

- (id)initWithToken:(NSString *)token {
    if (self = [super init]) {
        self.token = token;
    }
    return self;
}

- (void) uploadFile:(NSString *)filePath
                key:(NSString *)key
              extra:(QiniuPutExtra *)extra
{
    int __block retryHost = 0;
    QNProgress __block progressBlock;
    QNProgress __block __weak weakProgressBlock = progressBlock = ^(float percent) {
        if ([self.delegate respondsToSelector:@selector(uploadProgressUpdated:percent:)]) {
            [self.delegate uploadProgressUpdated:filePath percent:percent];
        }
    };
    
    QNComplete __block completeBlock;
    QNComplete __block __weak weakCompleteBlock = completeBlock = ^(AFHTTPRequestOperation *operation, NSError *error) {
        if (error) {
            if (retryHost == 0 && isRetryHost(operation)) {
                retryHost = 1;
                [QiniuClient uploadFile:filePath
                                    key:key
                                  token:self.token
                                  extra:extra
                                 uphost:kQiniuUpHost2
                               progress:weakProgressBlock
                               complete:weakCompleteBlock];
                return;
            }
            error = qiniuErrorWithOperation(operation, error);
            [self.delegate uploadFailed:filePath error:error];
        }else{
            NSDictionary *resp = operation.responseObject;
            [self.delegate uploadSucceeded:filePath ret:resp];
        }
    };
    
    [QiniuClient uploadFile:filePath
                        key:key
                      token:self.token
                      extra:extra
                     uphost:kQiniuUpHost
                   progress:weakProgressBlock
                   complete:weakCompleteBlock];

}

@end

