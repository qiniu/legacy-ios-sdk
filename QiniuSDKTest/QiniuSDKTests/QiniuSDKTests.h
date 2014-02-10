//
//  QiniuSDKTests.h
//  QiniuSDKTests
//
//  Created by Qiniu Developers 2013
//

#import <SenTestingKit/SenTestingKit.h>
#import "QiniuSimpleUploader.h"

@interface QiniuSDKTests : SenTestCase<QiniuUploadDelegate>
{
    bool _done;
    bool _progressReceived;
    NSString *_filePath;
    NSString *_token;
}

@end
