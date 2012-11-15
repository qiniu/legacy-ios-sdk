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

// FOR TEST ONLY!
//
// Note: AccessKey/SecretKey should not be included in client app.

#define kAccessKey @"hkgoe_cTFBVrR-pJsVwa3IEIfFeM5VwDHss0wxfw"
#define kSecretKey @"pjLQr9zlhFOkiU6fkTp4AqUi7TLr0LhLrHIVxRs4"


@implementation QiniuSDKTests

@synthesize filePath;
@synthesize token;

- (void)setUp
{
    [super setUp];
    
    self.filePath = [NSTemporaryDirectory() stringByAppendingPathComponent:@"test.png"];
    NSLog(@"Test file: %@", self.filePath);
    
    // Download a file and save to local path.
    
    NSFileManager *fileManager = [NSFileManager defaultManager];
    if (![fileManager fileExistsAtPath:self.filePath])
    {
        NSURL *url = [NSURL URLWithString:@"http://dizorb.com/wp-content/uploads/2010/02/Golden-Dream_Dizorb_dot_com.jpg"];
        NSData *data = [NSData dataWithContentsOfURL:url];
        
        [data writeToFile:self.filePath atomically:TRUE];
    }
    
    // Prepare the uptoken
    
    QiniuAuthPolicy *policy = [[QiniuAuthPolicy alloc] init];
    policy.callbackBodyType = @"";
    policy.callbackUrl = @"";
    policy.customer = @"";
    policy.expires = 0;
    policy.scope = @"bucket";
    
    self.token = [policy makeToken:kAccessKey secretKey:kSecretKey];
    
    [policy release];
    
    done = false;
    progressReceived = false;
}

- (void)tearDown
{
    // Tear-down code here.
    
    [super tearDown];
}

- (void)testAuthPolicyMarshal
{
    QiniuAuthPolicy *policy = [[QiniuAuthPolicy alloc] init];
    policy.callbackBodyType = @"application/json";
    policy.callbackUrl = @"<callbackUrl>";
    policy.customer = @"<customer>";
    policy.expires = 3600;
    policy.scope = @"bucket";
    
    NSString *policyJson = [policy marshal];
    
    STAssertNotNil(policyJson, @"Marshal of QiniuAuthPolicy failed.");
    
    NSString *thisToken = [policy makeToken:kAccessKey secretKey:kSecretKey];
    
    STAssertNotNil(thisToken, @"Failed to create token based on QiniuAuthPolicy.");

    [policy release];
}

- (void)uploadProgressUpdated:(NSString *)theFilePath percent:(float)percent
{
    progressReceived = true;
    
    NSLog(@"Progress Updated: %@ - %f", theFilePath, percent);
}

// Upload completed successfully.
- (void)uploadSucceeded:(NSString *)theFilePath hash:(NSString *)hash
{
    done = true;
    
    NSLog(@"Upload Succeeded: %@ - Hash: %@", theFilePath, hash);
}

// Upload failed.
- (void)uploadFailed:(NSString *)theFilePath error:(NSError *)error
{
    done = true;
    
    NSLog(@"Upload Failed: %@ - Reason: %@", theFilePath, error);
}

- (void) testSimpleUpload1
{
    QiniuSimpleUploader *uploader = [[QiniuSimpleUploader alloc] init];
    uploader.token = self.token;
    uploader.delegate = self;
    
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    [formatter setDateFormat: @"yyyy-MM-dd-HH-mm-ss-zzz"];
    
    NSString *timeDesc = [formatter stringFromDate:[NSDate date]];
    
    [uploader upload:self.filePath bucket:@"bucket" key:[NSString stringWithFormat:@"test-%@.png", timeDesc] extraParams:nil];

    int waitLoop = 0;
    while (!done && waitLoop < 10) // Wait for 10 seconds.
    {
        NSLog(@"Waiting for the result...");
        [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:1.0]];
        waitLoop++;
    }
    
    if (waitLoop == 10) {
        STFail(@"Failed to receive expected delegate messages.");
    }
    
    [uploader release];
}

@end