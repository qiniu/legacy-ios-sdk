//
//  QiniuBlockUploadDelegate.h
//  QiniuBlockUploadDelegate
//
//  Created by Qiniu Developers 2013
//

#import <Foundation/Foundation.h>
#import "QiniuBlkputRet.h"

@protocol QiniuBlockUploadDelegate <NSObject>

@required

- (void) uploadBlockProgress:(int)blockIndex putRet:(QiniuBlkputRet *)putRet;

@optional

- (void) uploadBlockSucceeded:(int)blockIndex putRet:(QiniuBlkputRet *)putRet;

- (void) uploadBlockFailed:(int)blockIndex error:(NSError *)error;

@end
