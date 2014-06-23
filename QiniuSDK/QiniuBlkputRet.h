//
//  QiniuBlkputRet.h
//  QiniuSDK
//
//  Created by ltz on 14-2-27.
//  Copyright (c) 2014年 Qiniu. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface QiniuBlkputRet : NSObject<NSCoding>

- (QiniuBlkputRet *)initWithDictionary:(NSDictionary *)dictionary;

@property (copy, nonatomic) NSString *ctx;
@property (copy, nonatomic) NSString *checksum;
@property (copy, nonatomic) NSString *host;

@property int crc32;
@property int offset;

@end
