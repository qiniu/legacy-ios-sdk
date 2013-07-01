//
//  QiniuPutExtra.h
//  QiniuSDK
//
//  Created by Qiniu Developers 2013
//

#import <Foundation/Foundation.h>

@interface QiniuPutExtra : NSObject

// user comtom params, refer to http://docs.qiniu.com/api/put.html#xVariables
@property (retain, nonatomic) NSDictionary *params;

// specify file's mimeType, or server side automatically determine the mimeType.
@property (copy, nonatomic) NSString *mimeType;

// specify file's crc32 value.
// server side can check it for integrity accodring to the value of checkCrc.
@property UInt32 crc32;

// if checkCrc is 0, server side will not check crc32.
// if checkCrc is 1, server side will check crc32 using the value of crc32.
@property UInt32 checkCrc;

@end
