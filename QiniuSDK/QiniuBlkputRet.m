//
//  QiniuBlkputRet.m
//  QiniuSDK
//
//  Created by Qiniu Developers 2013
//

#import "QiniuBlkputRet.h"
#import "QiniuConfig.h"

@implementation QiniuBlkputRet

@synthesize host;
@synthesize ctx;
@synthesize checksum;
@synthesize crc32;
@synthesize offset;

-(id) init {
    if (self = [super init]) {
        host = kQiniuUpHost;
        ctx = @"";
        checksum = @"";
        offset = 0;
    }
    return self;
}

-(void) dealloc {
    [host release];
    [ctx release];
    [checksum release];
    [super dealloc];
}

- (void) encodeWithCoder:(NSCoder *)aCoder {
    [aCoder encodeObject:host forKey:@"host"];
    [aCoder encodeObject:ctx forKey:@"ctx"];
    [aCoder encodeInt:offset forKey:@"offset"];
}

- (id) initWithCoder:(NSCoder *)aDecoder {
    if (self = [super init]) {
        self.host = [aDecoder decodeObjectForKey:@"host"];
        self.ctx = [aDecoder decodeObjectForKey:@"ctx"];
        self.offset = [aDecoder decodeIntForKey:@"offset"];
    }
    return self;
}

@end
