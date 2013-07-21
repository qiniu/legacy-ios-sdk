//
//  QiniuUploadDelegate.h
//  QiniuSDK
//
//  Created by Qiniu Developers 2013
//

#import <Foundation/Foundation.h>

@protocol QiniuUploadDelegate <NSObject>

@optional

// Progress updated. 1.0 indicates 100%.
- (void)uploadProgressUpdated:(NSString *)filePath percent:(float)percent;

@required

- (void)uploadSucceeded:(NSString *)filePath ret:(NSDictionary *)ret;

- (void)uploadFailed:(NSString *)filePath error:(NSError *)error;

@end
