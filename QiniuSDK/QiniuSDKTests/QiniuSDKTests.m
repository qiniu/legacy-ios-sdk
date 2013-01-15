//
//  QiniuSDKTests.m
//  QiniuSDKTests
//
//  Created by Hugh Lv on 12-11-14.
//  Copyright (c) 2012 Shanghai Qiniu Information Technologies Co., Ltd. All rights reserved.
//

#import "QiniuSDKTests.h"
#import "QiniuSimpleUploader.h"
#import "QiniuAuthPolicy.h"
#import "QiniuConfig.h"
#import <zlib.h>

// FOR TEST ONLY!
//
// Note: AccessKey/SecretKey should not be included in client app.

// NOTE: Please replace with your own accessKey/secretKey.
// You can find your keys on https://dev.qiniutek.com/ ,
#define kAccessKey @"<Please specify your access key>"
#define kSecretKey @"<Please specify your secret key>"

// NOTE: You need to replace value of kBucketValue with the key of an existing bucket.
// You can create a new bucket on https://dev.qiniutek.com/ .
#define kBucketName @"<Please specify your bucket name>"

@implementation QiniuSDKTests

- (void)setUp
{
    [super setUp];
    
    _filePath = [NSTemporaryDirectory() stringByAppendingPathComponent:@"test.png"];
    NSLog(@"Test file: %@", _filePath);
    
    // Download a file and save to local path.
    
    NSFileManager *fileManager = [NSFileManager defaultManager];
    if (![fileManager fileExistsAtPath:_filePath])
    {
        NSURL *url = [NSURL URLWithString:@"http://dizorb.com/wp-content/uploads/2010/02/Golden-Dream_Dizorb_dot_com.jpg"];
        NSData *data = [NSData dataWithContentsOfURL:url];
        
        [data writeToFile:_filePath atomically:TRUE];
    }
    
    // Prepare the uptoken
    
    QiniuAuthPolicy *policy = [[QiniuAuthPolicy new] autorelease];
    policy.expires = 3600;
    policy.scope = kBucketName;
    
    _token = [policy makeToken:kAccessKey secretKey:kSecretKey];

    _done = false;
    _progressReceived = false;
}

- (void)tearDown
{
    // Tear-down code here.
    [super tearDown];
}

- (void)testAuthPolicyMarshal
{
    QiniuAuthPolicy *policy = [[QiniuAuthPolicy new] autorelease];
    policy.expires = 3600;
    policy.scope = @"bucket";
    
    NSString *policyJson = [policy makeToken:kAccessKey secretKey:kSecretKey];
    
    STAssertNotNil(policyJson, @"Marshal of QiniuAuthPolicy failed.");
    
    NSString *thisToken = [policy makeToken:kAccessKey secretKey:kSecretKey];
    
    STAssertNotNil(thisToken, @"Failed to create token based on QiniuAuthPolicy.");
}

- (void)uploadProgressUpdated:(NSString *)theFilePath percent:(float)percent
{
    _progressReceived = true;
    
    NSLog(@"Progress Updated: %@ - %f", theFilePath, percent);
}

// Upload completed successfully.
- (void)uploadSucceeded:(NSString *)theFilePath hash:(NSString *)hash
{
    _done = true;
    
    NSLog(@"Upload Succeeded: %@ - Hash: %@", theFilePath, hash);
}

// Upload failed.
- (void)uploadFailed:(NSString *)theFilePath error:(NSError *)error
{
    _done = true;
    
    NSLog(@"Upload Failed: %@ - Reason: %@", theFilePath, error);
}

- (void) testSimpleUpload1
{
    QiniuSimpleUploader *uploader = [QiniuSimpleUploader uploaderWithToken:_token];
    uploader.delegate = self;
    
    NSDateFormatter *formatter = [[[NSDateFormatter alloc] init] autorelease];
    [formatter setDateFormat: @"yyyy-MM-dd-HH-mm-ss-zzz"];
    
    NSString *timeDesc = [formatter stringFromDate:[NSDate date]];
    
    [uploader upload:_filePath bucket:kBucketName key:[NSString stringWithFormat:@"test-%@.png", timeDesc] extraParams:nil];

    int waitLoop = 0;
    while (!_done && waitLoop < 10) // Wait for 10 seconds.
    {
        NSLog(@"Waiting for the result...");
        [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:1.0]];
        waitLoop++;
    }
    
    if (waitLoop == 10) {
        STFail(@"Failed to receive expected delegate messages.");
    }
}

// Test case: CRC parameter. This case is to verify that a wrong CRC should cause a failure.
- (void) testCrc32_1
{
    QiniuSimpleUploader *uploader = [QiniuSimpleUploader uploaderWithToken:_token];
    uploader.delegate = self;
    
    NSDateFormatter *formatter = [[[NSDateFormatter alloc] init] autorelease];
    [formatter setDateFormat: @"yyyy-MM-dd-HH-mm-ss-zzz"];
    
    NSString *timeDesc = [formatter stringFromDate:[NSDate date]];
    
    // An incorrect CRC string.
    NSDictionary *params = [NSDictionary dictionaryWithObjectsAndKeys:@"1234567890", kCrc32Key, nil];
    
    [uploader upload:_filePath bucket:kBucketName key:[NSString stringWithFormat:@"test-%@.png", timeDesc] extraParams:params];
    
    int waitLoop = 0;
    while (!_done && waitLoop < 10) // Wait for 10 seconds.
    {
        NSLog(@"Waiting for the result...");
        [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:1.0]];
        waitLoop++;
    }
    
    if (waitLoop == 10) {
        STFail(@"Failed to receive expected delegate messages.");
    }
}

// Test case: CRC parameter. This case is to verify that a wrong CRC should cause a failure.
- (void) testCrc32_2
{
    QiniuSimpleUploader *uploader = [QiniuSimpleUploader uploaderWithToken:_token];
    uploader.delegate = self;
    
    NSDateFormatter *formatter = [[[NSDateFormatter alloc] init] autorelease];
    [formatter setDateFormat: @"yyyy-MM-dd-HH-mm-ss-zzz"];
    
    NSString *timeDesc = [formatter stringFromDate:[NSDate date]];
    
    NSData *buffer = [NSData dataWithContentsOfFile:_filePath];
    
    uLong crc = crc32(0L, Z_NULL, 0);
    crc = crc32(crc, [buffer bytes], [buffer length]);
    
    NSString *crcStr = [NSString stringWithFormat:@"%lu", crc];

    // A correct CRC string.
    NSDictionary *params = [NSDictionary dictionaryWithObjectsAndKeys:crcStr, kCrc32Key, nil];
    
    [uploader upload:_filePath bucket:kBucketName key:[NSString stringWithFormat:@"test-%@.png", timeDesc] extraParams:params];
    
    int waitLoop = 0;
    while (!_done && waitLoop < 10) // Wait for 10 seconds.
    {
        NSLog(@"Waiting for the result...");
        [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:1.0]];
        waitLoop++;
    }
    
    if (waitLoop == 10) {
        STFail(@"Failed to receive expected delegate messages.");
    }
}


@end