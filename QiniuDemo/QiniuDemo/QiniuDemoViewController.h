//
//  QiniuDemoViewController.h
//  QiniuDemo
//
//  Created by ltz on 14-2-28.
//  Copyright (c) 2014年 Qiniu. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "QiniuSimpleUploader.h"
#import "QiniuResumableUploader.h"

@interface QiniuDemoViewController : UIViewController<QiniuUploadDelegate,UITextFieldDelegate>


@property (retain, nonatomic)QiniuRioPutExtra *extra;
@property (retain, nonatomic)QiniuResumableUploader *rUploader;
@property (retain, nonatomic)QiniuSimpleUploader *sUploader;
@property (copy, nonatomic)NSString *filePath;
@property (copy, nonatomic)NSString *lastResumableKey;
@property (copy, nonatomic)NSString *token;

@end
