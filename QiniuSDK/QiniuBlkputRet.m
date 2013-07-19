//
//  QiniuBlkputRet.m
//  QiniuSDK
//
//  Created by Qiniu Developers 2013
//

#import "QiniuBlkputRet.h"

@implementation QiniuBlkputRet

@synthesize host;
@synthesize ctx;
@synthesize checksum;
@synthesize crc32;
@synthesize offset;

-(id) init {
    return [super init];
}

-(void) dealloc {
    [host release];
    [ctx release];
    [checksum release];
    [super dealloc];
}

@end
