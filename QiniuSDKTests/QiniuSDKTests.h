//
//  QiniuSDKTests.h
//  QiniuSDKTests
//
//  Created by Qiniu Developers 2013
//

#import <XCTest/XCTest.h>
#import "QiniuSimpleUploader.h"

@interface QiniuSDKTests : XCTestCase<QiniuUploadDelegate>
{
    BOOL _succeed;
    BOOL _done;
    BOOL _progressReceived;
    NSError *_error;
    NSDictionary *_retDictionary;
    
    NSString *_filePath;
    NSString *_fileMedium;
    NSString *_fileLarge;
    NSString *_token;
}

@end
