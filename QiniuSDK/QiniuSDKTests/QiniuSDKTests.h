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
    bool _done;
    bool _progressReceived;
    NSString *_filePath;
    NSString *_token;
}

@end
