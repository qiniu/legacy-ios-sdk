//
//  QiniuResumablePutExtra.h
//  QiniuSDK
//
//  Created by Qiniu Developers 2013
//

#import <Foundation/Foundation.h>
#import "QiniuBlkputRet.h"
#import "QiniuBlockUploadDelegate.h"

@interface QiniuRioPutExtra : NSObject

@property (copy, nonatomic) NSString* callbackParams;
@property (copy, nonatomic) NSString* bucket;
@property (copy, nonatomic) NSString* mimeType;
@property UInt32 chunkSize;
@property UInt32 tryTimes;
@property (retain, nonatomic) NSMutableArray* progresses;
@property (assign) id<QiniuBlockUploadDelegate> blockNotify;

@end
