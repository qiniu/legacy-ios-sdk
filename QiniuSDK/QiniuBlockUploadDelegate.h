//
//  QiniuBlockUploadDelegate.h
//  QiniuBlockUploadDelegate
//
//  Created by Qiniu Developers 2013
//

#import <Foundation/Foundation.h>

@protocol QiniuBlockUploadDelegate <NSObject>

- (void) uploadBlockProgress:(int)blockIndex putRet:(NSDictionary *)putRet;

- (void) uploadBlockSucceeded:(int)blockIndex atHost:(NSString *)host context:(NSString *)context;

- (void) uploadBlockFailed:(int)blockIndex error:(NSError *)error;

@end
