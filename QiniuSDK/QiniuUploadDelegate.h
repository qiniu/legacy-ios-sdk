//
//  QiniuUploadDelegate.h
//  QiniuSDK
//
//  Created by Hugh Lv on 12-11-13.
//  Copyright (c) 2012 Shanghai Qiniu Information Technologies Co., Ltd. All rights reserved.
//

#import <Foundation/Foundation.h>

// ------------------------------------------------------------------------------------

// Upload delegates. Should be implemented by callers to receive callback info.

@protocol QiniuUploadDelegate <NSObject>

@optional

// Progress updated. 1.0 indicates 100%.
- (void)uploadProgressUpdated:(NSString *)filePath percent:(float)percent;

// Upload completed successfully.
- (void)uploadSucceeded:(NSString *)filePath hash:(NSString *)hash;

// Upload failed.
- (void)uploadFailed:(NSString *)filePath error:(NSError *)error;

@end
