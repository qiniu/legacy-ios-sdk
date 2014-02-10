//
//  QiniuSDKTests.m
//  QiniuSDKTests
//
//  Created by Qiniu Developers 2013
//

#import "QiniuSDKTests.h"
#import "QiniuPutPolicy.h"
#import "QiniuConfig.h"
#import <zlib.h>

// FOR TEST ONLY!
//
// Note: AccessKey/SecretKey should not be included in client app.

// NOTE: Please replace with your own accessKey/secretKey.
// You can find your keys on https://portal.qiniu.com ,
static NSString *QiniuAccessKey = @"<Please specify your access key>";
static NSString *QiniuSecretKey = @"<Please specify your secret key>";
static NSString *QiniuBucketName = @"<Please specify your bucket name>";

#define kWaitTime 10 // seconds

@implementation QiniuSDKTests

- (void)setUp
{
    [super setUp];
    
    QiniuAccessKey = @"iyfeOR5ULAq4o_8LHslWEJZAf-CAEgpQExWxMvpQ";
    QiniuSecretKey = @"--hLnvubaeE1OhsexDsyHSiDS9Eyl9sqgNH9iyj7";
    QiniuBucketName = @"test";
    
    _filePath = [NSTemporaryDirectory() stringByAppendingPathComponent:@"test1.png"];
    NSLog(@"Test file: %@", _filePath);
    
    // Download a file and save to local path.
    NSFileManager *fileManager = [NSFileManager defaultManager];
    if (![fileManager fileExistsAtPath:_filePath])
    {
        NSURL *url = [NSURL URLWithString:@"http://qiniuphotos.qiniudn.com/gogopher.jpg"];
        NSData *data = [NSData dataWithContentsOfURL:url];
        [data writeToFile:_filePath atomically:TRUE];
    }
    
    // Prepare the uptoken
    QiniuPutPolicy *policy = [QiniuPutPolicy new] ;
    policy.expires = 3600;
    policy.scope = QiniuBucketName;
    _token = [policy makeToken:QiniuAccessKey secretKey:QiniuSecretKey];

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
    QiniuPutPolicy *policy = [QiniuPutPolicy new] ;
    policy.expires = 3600;
    policy.scope = @"bucket";
    
    NSString *policyJson = [policy makeToken:QiniuAccessKey secretKey:QiniuSecretKey];
    STAssertNotNil(policyJson, @"Marshal of QiniuAuthPolicy failed.");
    
    NSString *thisToken = [policy makeToken:QiniuAccessKey secretKey:QiniuSecretKey];
    STAssertNotNil(thisToken, @"Failed to create token based on QiniuAuthPolicy.");
}

// Upload progress
- (void)uploadProgressUpdated:(NSString *)theFilePath percent:(float)percent
{
    _progressReceived = true;
    NSLog(@"Progress Updated: %@ - %f", theFilePath, percent);
}

// Upload completed successfully
- (void)uploadSucceeded:(NSString *)theFilePath ret:(NSDictionary *)ret
{
    _done = true;
    NSLog(@"Upload Succeeded: %@ - Ret: %@", theFilePath, ret);
}

// Upload failed
- (void)uploadFailed:(NSString *)theFilePath error:(NSError *)error
{
    _done = true;
    NSLog(@"Upload Failed: %@ - Reason: %@", theFilePath, error);
}

- (NSString *) timeString {
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init] ;
    [formatter setDateFormat: @"yyyy-MM-dd-HH-mm-ss-zzz"];
    return [formatter stringFromDate:[NSDate date]];
}

- (void) waitFinish {
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

- (void) testSimpleUpload
{
    QiniuSimpleUploader *uploader = [QiniuSimpleUploader uploaderWithToken:_token];
    uploader.delegate = self;
    [uploader uploadFile:_filePath key:[NSString stringWithFormat:@"test-%@.png", [self timeString]] extra:nil];
    [self waitFinish];
}

- (void) testSimpleUploadWithUndefinedKey
{
    QiniuSimpleUploader *uploader = [QiniuSimpleUploader uploaderWithToken:_token];
    uploader.delegate = self;
    [uploader uploadFile:_filePath key:kQiniuUndefinedKey extra:nil];
    [self waitFinish];
}


- (void) testSimpleUploadWithReturnBodyAndUserParams
{
    QiniuPutPolicy *policy = [QiniuPutPolicy new];
    policy.expires = 3600;
    policy.scope = QiniuBucketName;
    policy.endUser = @"ios-sdk-test";
    policy.returnBody = @"{\"bucket\":$(bucket),\"key\":$(key),\"type\":$(mimeType),\"w\":$(imageInfo.width),\"xfoo\":$(x:foo),\"endUser\":$(endUser)}";
    _token = [policy makeToken:QiniuAccessKey secretKey:QiniuSecretKey];
    
    QiniuSimpleUploader *uploader = [QiniuSimpleUploader uploaderWithToken:_token];
    uploader.delegate = self;
    
    // extra argument
    QiniuPutExtra *extra = [[QiniuPutExtra alloc] init];
    extra.params = @{@"x:foo": @"fooName"};
    
    // upload
    [uploader uploadFile:_filePath key:[NSString stringWithFormat:@"test-%@.png", [self timeString]] extra:extra];
    [self waitFinish];
}

- (void) testSimpleUploadWithWrongCrc32
{
    QiniuSimpleUploader *uploader = [QiniuSimpleUploader uploaderWithToken:_token];
    uploader.delegate = self;
    
    // wrong crc32 value
    QiniuPutExtra *extra = [[QiniuPutExtra alloc] init] ;
    extra.crc32 = 123456;
    extra.checkCrc = 1;
    
    // upload
    [uploader uploadFile:_filePath key:[NSString stringWithFormat:@"test-%@.png", [self timeString]] extra:extra];
    [self waitFinish];
}

- (void) testSimpleUploadWithRightCrc32
{
    QiniuSimpleUploader *uploader = [QiniuSimpleUploader uploaderWithToken:_token];
    uploader.delegate = self;
    
    // calc right crc32 value
    NSData *buffer = [NSData dataWithContentsOfFile:_filePath];
    uLong crc = crc32(0L, Z_NULL, 0);
    crc = crc32(crc, [buffer bytes], [buffer length]);
    
    // extra argument with right crc32
    QiniuPutExtra *extra = [[QiniuPutExtra alloc] init];
    extra.crc32 = crc;
    extra.checkCrc = 1;
    
    // upload
    [uploader uploadFile:_filePath key:[NSString stringWithFormat:@"test-%@.png", [self timeString]] extra:extra];
    [self waitFinish];
}

@end