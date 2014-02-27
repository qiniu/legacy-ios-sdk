//
//  QiniuResumablePutExtra.m
//  QiniuSDK
//
//  Created by Qiniu Developers 2013
//

#import "QiniuRioPutExtra.h"

@implementation QiniuRioPutExtra

@synthesize callbackParams;
@synthesize bucket;
@synthesize mimeType;
@synthesize chunkSize;
@synthesize tryTimes;
@synthesize concurrentNum;
@synthesize progresses;
@synthesize notify;
@synthesize notifyErr;

-(id) init {
    return [super init];
}

-(void) dealloc {
    [callbackParams release];
    [bucket release];
    [mimeType release];
    [progresses release];
    Block_release(notify);
    Block_release(notifyErr);
    [super dealloc];
}

@end
