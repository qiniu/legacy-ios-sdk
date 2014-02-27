//
//  QiniuBlkputRet.m
//  QiniuSDK
//
//  Created by ltz on 14-2-27.
//  Copyright (c) 2014年 Qiniu. All rights reserved.
//

#import "QiniuBlkputRet.h"

@implementation QiniuBlkputRet

- (QiniuBlkputRet *)initWithDictionary:(NSDictionary *)dictionary
{
    self = [super init];
    
    self.ctx = [dictionary valueForKey:@"ctx"];
    self.crc32 = [[dictionary valueForKey:@"crc32"] intValue];
    self.offset = [[dictionary valueForKey:@"offset"] intValue];
    self.host = [dictionary valueForKey:@"host"];
    
    return self;
}

- (void) encodeWithCoder:(NSCoder *)aCoder {
    [aCoder encodeObject:self.host forKey:@"host"];
    [aCoder encodeObject:self.ctx forKey:@"ctx"];
    [aCoder encodeInt:self.offset forKey:@"offset"];
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