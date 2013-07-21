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

- (void) uploadBlockProgress:(int)blockIndex blockSize:(int)blockSize putRet:(QiniuBlkputRet *)putRet;

- (void) uploadBlockSucceeded:(int)blockIndex blockSize:(int)blockSize;

- (void) uploadBlockFailed:(int)blockIndex blockSize:(int)blockSize error:(NSError *)error;

@end
