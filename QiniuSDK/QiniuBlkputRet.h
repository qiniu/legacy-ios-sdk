//
//  QiniuBlkputRet.h
//  QiniuSDK
//
//  Created by Qiniu Developers 2013
//

#import <Foundation/Foundation.h>

@interface QiniuBlkputRet : NSObject<NSCoding>

@property (copy, nonatomic) NSString* host;
@property (copy, nonatomic) NSString* ctx;
@property (copy, nonatomic) NSString* checksum;
@property UInt32 crc32;
@property int offset;

@end
