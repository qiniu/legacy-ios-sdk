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
@synthesize progresses;
@synthesize blockNotify;

-(id) init {
    return [super init];
}

-(void) dealloc {
    [callbackParams release];
    [bucket release];
    [mimeType release];
    [progresses release];
    [super dealloc];
}

@end
