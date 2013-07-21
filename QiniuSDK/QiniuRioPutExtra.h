//
//  QiniuResumablePutExtra.h
//  QiniuSDK
//
//  Created by Qiniu Developers 2013
//

#import <Foundation/Foundation.h>
#import "QiniuBlkputRet.h"
#import "QiniuBlockNotifier.h"

typedef void (^QiniuRioNotify)(int blockIndex, int blockSize, QiniuBlkputRet* ret);
typedef void (^QiniuRioNotifyErr)(int blockIndex, int blockSize, NSError* error);

@interface QiniuRioPutExtra : NSObject

@property (copy, nonatomic) NSString* callbackParams;
@property (copy, nonatomic) NSString* bucket;
@property (copy, nonatomic) NSString* mimeType;
@property UInt32 chunkSize;
@property UInt32 tryTimes;
@property UInt32 concurrentNum;
@property (retain, nonatomic) NSMutableArray* progresses;
@property (copy) QiniuRioNotify notify;
@property (copy) QiniuRioNotifyErr notifyErr;

@end
