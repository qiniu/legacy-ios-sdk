//
//  QiniuSDKTests.h
//  QiniuSDKTests
//
//  Created by Hugh Lv on 12-11-14.
//  Copyright (c) 2012年 Shanghai Qiniu Information Technologies Co., Ltd. All rights reserved.
//

#import <SenTestingKit/SenTestingKit.h>
#import "QiniuUploadDelegate.h"

@interface QiniuSDKTests : SenTestCase<QiniuUploadDelegate>
{
    NSString *filePath;
    NSString *token;
    
    bool done;
    bool progressReceived;
}

@property (retain, nonatomic) NSString *filePath;
@property (retain, nonatomic) NSString *token;

@end
