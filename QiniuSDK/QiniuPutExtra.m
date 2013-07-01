//
//  QiniuPutExtra.m
//  QiniuSDK
//
//  Created by Qiniu Developers 2013
//

#import "QiniuPutExtra.h"

@implementation QiniuPutExtra

@synthesize params;
@synthesize mimeType;
@synthesize crc32;
@synthesize checkCrc;

-(id) init {
    return [super init];
}

-(void) dealloc {
    [params release];
    [mimeType release];
    [super dealloc];
}

@end
