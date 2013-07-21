//
//  QiniuResumableUploadDemo.h
//  QiniuDemo
//
//  Created by Qiniu Developers 2013
//

#import <Foundation/Foundation.h>
#import "../../QiniuSDK/QiniuUploadDelegate.h"

@interface QiniuResumableUploadDemo : NSObject<QiniuUploadDelegate>
{
    int _blockCount;
    NSMutableArray* _progresses;
    NSString *_filePath;
    NSString *_persistenceDir;
    NSString *_token;
}

- (id) initWithFile:(NSString *)filePath persistenceDir:(NSString *)dir;

- (void) resumalbleUpload:(NSString *)key;

@end
