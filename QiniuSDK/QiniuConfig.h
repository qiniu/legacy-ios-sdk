//
//  QiniuConfig.h
//  QiniuSDK
//
//  Created by Qiniu Developers 2013
//

#import <Foundation/Foundation.h>

#define kQiniuUpHost @"http://up.qiniu.com"

#define kQiniuUndefinedKey @"?"

#define kQiniuBlockSize (4 * 1024 * 1024)  // 4MB
#define kQiniuChunkSize (128 * 1024) // 128KB
#define kQiniuRetryTimes 3
#define kQiniuMaxConcurrentUploads 4
