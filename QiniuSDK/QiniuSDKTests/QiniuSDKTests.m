//
//  QiniuSDKTests.m
//  QiniuSDKTests
//
//  Created by Qiniu Developers 2013
//

#import "QiniuSDKTests.h"
#import "QiniuSimpleUploader.h"
#import "QiniuResumableUploader.h"
#import "QiniuPutPolicy.h"
#import "QiniuPutExtra.h"
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

#define kWaitTime 20 // seconds

@implementation QiniuSDKTests

- (void)setUp
{
    [super setUp];
    
    QiniuAccessKey = @"dbsrtUEWFt_HMlY59qw5KqaydbvML1zxtxsvioUX";
    QiniuSecretKey = @"EZUwWLGLfbq0y94SLteofzzqKc60Dxg5kc1Rv2ct";
    QiniuBucketName = @"shijy";
    
    _filePath = [NSTemporaryDirectory() stringByAppendingPathComponent:@"test.jpg"];
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
    QiniuPutPolicy *policy = [[QiniuPutPolicy new] autorelease];
    policy.expires = 3600;
    policy.scope = QiniuBucketName;
    _token = [policy makeToken:QiniuAccessKey secretKey:QiniuSecretKey];

    _done = false;
    _succeed = false;
    _progressReceived = false;
}

- (void)reset
{
    _done = false;
    _succeed = false;
    _progressReceived = false;
}

- (void)tearDown
{
    // Tear-down code here.
    [super tearDown];
}

- (void)testAuthPolicyMarshal
{
    QiniuPutPolicy *policy = [[QiniuPutPolicy new] autorelease];
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
    _succeed = true;
    NSLog(@"Upload Succeeded: %@ - Ret: %@", theFilePath, ret);
}

// Upload failed
- (void)uploadFailed:(NSString *)theFilePath error:(NSError *)error
{
    _done = true;
    NSLog(@"Upload Failed: %@ - Reason: %@", theFilePath, error);
}

- (NSString *) timeString {
    NSDateFormatter *formatter = [[[NSDateFormatter alloc] init] autorelease];
    [formatter setDateFormat: @"yyyy-MM-dd-HH-mm-ss-zzz"];
    return [formatter stringFromDate:[NSDate date]];
}

- (void) waitFinish {
    int waitLoop = 0;
    while (!_done && waitLoop < kWaitTime) // Wait for 10 seconds.
    {
        NSLog(@"Waiting for the result...");
        [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:1.0]];
        waitLoop++;
    }
    if (waitLoop == kWaitTime) {
        STFail(@"Failed to receive expected delegate messages.");
    }
}

- (void) testSimpleUpload
{
    [self reset];
    QiniuSimpleUploader *uploader = [QiniuSimpleUploader uploaderWithToken:_token];
    uploader.delegate = self;
    [uploader uploadFile:_filePath key:[NSString stringWithFormat:@"test-%@.png", [self timeString]] extra:nil];
    [self waitFinish];
    STAssertTrue(_succeed, @"upload should succeed");

}

- (void) testSimpleUploadWithUndefinedKey
{
    [self reset];
    QiniuSimpleUploader *uploader = [QiniuSimpleUploader uploaderWithToken:_token];
    uploader.delegate = self;
    [uploader uploadFile:_filePath key:kQiniuUndefinedKey extra:nil];
    [self waitFinish];
    STAssertTrue(_succeed, @"upload should succeed");
}


- (void) testSimpleUploadWithReturnBodyAndUserParams
{
    [self reset];
    QiniuPutPolicy *policy = [[QiniuPutPolicy new] autorelease];
    policy.expires = 3600;
    policy.scope = QiniuBucketName;
    policy.endUser = @"ios-sdk-test";
    policy.returnBody = @"{\"bucket\":$(bucket),\"key\":$(key),\"type\":$(mimeType),\"w\":$(imageInfo.width),\"xfoo\":$(x:foo),\"endUser\":$(endUser)}";
    _token = [policy makeToken:QiniuAccessKey secretKey:QiniuSecretKey];
    
    QiniuSimpleUploader *uploader = [QiniuSimpleUploader uploaderWithToken:_token];
    uploader.delegate = self;
    
    // extra argument
    QiniuPutExtra *extra = [[[QiniuPutExtra alloc] init] autorelease];
    extra.params = @{@"x:foo": @"fooName"};
    
    // upload
    [uploader uploadFile:_filePath key:[NSString stringWithFormat:@"test-%@.png", [self timeString]] extra:extra];
    [self waitFinish];
    STAssertTrue(_succeed, @"upload should succeed");
}

- (void) testSimpleUploadWithWrongCrc32
{
    [self reset];
    QiniuSimpleUploader *uploader = [QiniuSimpleUploader uploaderWithToken:_token];
    uploader.delegate = self;
    
    // wrong crc32 value
    QiniuPutExtra *extra = [[[QiniuPutExtra alloc] init] autorelease];
    extra.crc32 = 123456;
    extra.checkCrc = 1;
    
    // upload
    [uploader uploadFile:_filePath key:[NSString stringWithFormat:@"test-%@.png", [self timeString]] extra:extra];
    [self waitFinish];
    STAssertFalse(_succeed, @"upload should fail");
}

- (void) testSimpleUploadWithRightCrc32
{
    [self reset];
    QiniuSimpleUploader *uploader = [QiniuSimpleUploader uploaderWithToken:_token];
    uploader.delegate = self;
    
    // calc right crc32 value
    NSData *buffer = [NSData dataWithContentsOfFile:_filePath];
    uLong crc = crc32(0L, Z_NULL, 0);
    crc = crc32(crc, [buffer bytes], [buffer length]);
    
    // extra argument with right crc32
    QiniuPutExtra *extra = [[[QiniuPutExtra alloc] init] autorelease];
    extra.crc32 = crc;
    extra.checkCrc = 1;
    
    // upload
    [uploader uploadFile:_filePath key:[NSString stringWithFormat:@"test-%@.png", [self timeString]] extra:extra];
    [self waitFinish];
    STAssertTrue(_succeed, @"upload should succeed");
}

- (void) testSimpleUploadWithNegativeCrc32
{
    [self reset];
    QiniuSimpleUploader *uploader = [QiniuSimpleUploader uploaderWithToken:_token];
    uploader.delegate = self;
    
    // calc right crc32 value
  //  NSData *buffer = [NSData dataWithContentsOfFile:_filePath];

    NSData *buffer = [@"Hello, World!" dataUsingEncoding:NSUTF8StringEncoding];
    uLong crc = crc32(0L, Z_NULL, 0);
    crc = crc32(crc, [buffer bytes], [buffer length]);
    
    // extra argument with right crc32
    QiniuPutExtra *extra = [[[QiniuPutExtra alloc] init] autorelease];
    extra.crc32 = crc;
    extra.checkCrc = 1;
    NSLog(@"crc32: %lu", crc);
    
    NSString *crcpath = [NSTemporaryDirectory() stringByAppendingPathComponent:@"testcrc"];
    [buffer writeToFile:_filePath atomically:TRUE];

    // upload
    [uploader uploadFile:crcpath key:[NSString stringWithFormat:@"test-%@.png", [self timeString]] extra:extra];
    [self waitFinish];
    STAssertTrue(_succeed, @"upload should succeed");
}

- (void) testResumableUpload
{
    [self reset];
    QiniuResumableUploader *uploader = [QiniuResumableUploader instanceWithToken: _token];
    uploader.delegate = self;
    NSString *key = [NSString stringWithFormat:@"test-%@.png", [self timeString]];
    QiniuRioPutExtra *params = [[[QiniuRioPutExtra alloc] init] autorelease];
    params.bucket = QiniuBucketName;
    params.progresses = nil; // if resumalble upload, it contain progress of blocks
    // block progress persistence
    params.notify = ^(int blockIndex, int blockSize, QiniuBlkputRet* ret) {
        NSLog(@"notify for data persistence, blockIndex:%d, blockSize:%d, offset:%d ctx:%@",
              blockIndex, blockSize, (unsigned int)ret.offset, ret.ctx);
    };
    params.notifyErr = ^(int blockIndex, int blockSize, NSError* error) {
        NSLog(@"notify for block upload failed, blockIndex:%d, blockSize:%d, error:%@",
              blockIndex, blockSize, error);
    };
    [uploader uploadFile:_filePath key:key params:params];
    NSLog(@"key: %@\n", key);
    [self waitFinish];
    STAssertTrue(_succeed, @"upload should succeed");
}

@end
