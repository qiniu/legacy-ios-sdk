//
//  QiniuResumableUploadDemo.h
//  QiniuDemo
//
//  Created by Qiniu Developers 2013
//

#import <Foundation/Foundation.h>
#import "../../QiniuSDK/QiniuUploadDelegate.h"
#import "../../QiniuSDK/QiniuResumableUploader.h"

@interface QiniuResumableUploadDemo : NSObject<QiniuUploadDelegate>
{
    NSMutableArray* _progresses;
    NSString *_filePath;
    NSString *_persistenceDir;
    QiniuResumableUploader *_uploader;
}

@property (copy) NSString *token;

- (id) initWithToken:(NSString *)token;

- (void) resumalbleUploadFile:(NSString *)filePath persistenceDir:(NSString *)dir bucket:(NSString *)bucket key:(NSString *)key;

- (void) stopUpload;

@end
