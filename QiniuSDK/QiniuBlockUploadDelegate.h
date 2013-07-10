//
//  QiniuBlockUploadDelegate.h
//  ResumalbleUpload
//
//  Created by 时 嘉赟 on 6/30/13.
//  Copyright (c) 2013 时 嘉赟. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol QiniuBlockUploadDelegate <NSObject>

- (void) uploadBlockProgress:(int)blockIndex putRet:(NSDictionary *)putRet;

- (void) uploadBlockSucceeded:(int)blockIndex atHost:(NSString *)host context:(NSString *)context;

- (void) uploadBlockFailed:(int)blockIndex error:(NSError *)error;

@end
