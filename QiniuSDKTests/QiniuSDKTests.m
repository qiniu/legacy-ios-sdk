//
//  QiniuSDKTests.m
//  QiniuSDKTests
//
//  Created by Qiniu Developers 2013
//

#import "QiniuSDKTests.h"
#import "QiniuConfig.h"
#import <zlib.h>

#define kWaitTime 40 // seconds

@implementation QiniuSDKTests

- (void)setUp
{
    [super setUp];
    
    _filePath = [NSTemporaryDirectory() stringByAppendingPathComponent:@"test1.png"];
    _fileMedium = [NSTemporaryDirectory() stringByAppendingPathComponent:@"medium.mp4"];
    _fileLarge = [NSTemporaryDirectory() stringByAppendingPathComponent:@"large.mp4"];
    NSLog(@"Test file: %@", _filePath);
    
    // Download a file and save to local path.
    NSFileManager *fileManager = [NSFileManager defaultManager];
    if (![fileManager fileExistsAtPath:_filePath])
    {
        NSURL *url = [NSURL URLWithString:@"http://qiniuphotos.qiniudn.com/gogopher.jpg"];
        NSData *data = [NSData dataWithContentsOfURL:url];
        [data writeToFile:_filePath atomically:TRUE];
    }
    
    if (![fileManager fileExistsAtPath:_fileMedium])
    {
        NSURL *url = [NSURL URLWithString:@"http://shars.qiniudn.com/outcrf.mp4"];
        NSData *data = [NSData dataWithContentsOfURL:url];
        [data writeToFile:_fileMedium atomically:TRUE];
    }
    
    // Prepare the uptoken
    // token with a year, 14.2.23
    _token = @"6UOyH0xzsnOF-uKmsHgpi7AhGWdfvI8glyYV3uPg:m-8jeXMWC-4kstLEHEMCfZAZnWc=:eyJkZWFkbGluZSI6MTQyNDY4ODYxOCwic2NvcGUiOiJ0ZXN0MzY5In0=";

    _done = false;
    _progressReceived = false;
}

- (void)tearDown
{
//    NSFileManager *fileManager = [NSFileManager defaultManager];
//    [fileManager removeItemAtPath:_filePath error:Nil];
    
    // Tear-down code here.
    [super tearDown];
}


// Upload progress
- (void)uploadProgressUpdated:(NSString *)theFilePath percent:(float)percent
{
    _progressReceived = YES;
    NSLog(@"Progress Updated: %@ - %f", theFilePath, percent);
}
// */

// Upload completed successfully
- (void)uploadSucceeded:(NSString *)theFilePath ret:(NSDictionary *)ret
{
    _done = YES;
    _succeed = YES;
    _retDictionary = ret;
    NSLog(@"Upload Succeeded: %@ - Ret: %@", theFilePath, ret);
}

// Upload failed
- (void)uploadFailed:(NSString *)theFilePath error:(NSError *)error
{
    _done = YES;
    _error = error;
    NSLog(@"Upload Failed: %@ - Reason: %@", theFilePath, error);
}

- (NSString *) timeString {
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    [formatter setDateFormat: @"yyyy-MM-dd-HH-mm-ss-zzz"];
    return [formatter stringFromDate:[NSDate date]];
}

- (void) waitFinish {
    int waitLoop = kWaitTime;
    while (!_done && waitLoop > 0) // Wait for 10 seconds.
    {
//        NSLog(@"Waiting for the result...");
        [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:1.0]];
        waitLoop--;
    }
    if (waitLoop <= 0) {
        XCTFail(@"Failed to receive expected delegate messages.");
    }
}


- (void) testSimpleUpload
{
    QiniuSimpleUploader *uploader = [QiniuSimpleUploader uploaderWithToken:_token];
    uploader.delegate = self;
    [uploader uploadFile:_filePath key:[NSString stringWithFormat:@"test-%@.png", [self timeString]] extra:nil];
    [self waitFinish];
    XCTAssertEqual(_succeed, YES, "SimpleUpload failed, error: %@", _error);
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

- (void)testResumableUploadSmall
{
    QiniuResumableUploader *uploader = [[QiniuResumableUploader alloc] initWithToken:_token];
    uploader.delegate = self;
    
    NSLog(@"resumable upload");
    [uploader uploadFile:_filePath key:[NSString stringWithFormat:@"test-%@.png", [self timeString]] extra:nil];
    [self waitFinish];
    XCTAssertEqual(_succeed, YES, "ResumableUpload failed, error: %@", _error);
}

  // */

- (void)testResumableUploadWithParam
{
    QiniuResumableUploader *uploader = [[QiniuResumableUploader alloc] initWithToken:_token];
    uploader.delegate = self;
    
    NSDictionary *params = [NSDictionary dictionaryWithObject:@"iamaiosdeveloper" forKey:@"x:cus"];
    QiniuRioPutExtra *extra = [QiniuRioPutExtra extraWithParams:params];
    extra.notify = ^(int blockIndex, int blockSize, QiniuBlkputRet* ret) {
        NSLog(@"notify for data persistence, blockIndex:%d, blockSize:%d, offset:%d ctx:%@",
              blockIndex, blockSize, (unsigned int)ret.offset, ret.ctx);
    };
    extra.notifyErr = ^(int blockIndex, int blockSize, NSError* error) {
        NSLog(@"notify for block upload failed, blockIndex:%d, blockSize:%d, error:%@",
              blockIndex, blockSize, error);
    };
    extra.concurrentNum = 1;

    [uploader uploadFile:_filePath key:[NSString stringWithFormat:@"test-params-%@.png", [self timeString]] extra:extra];

    [self waitFinish];
    XCTAssertEqual(_succeed, YES, "ResumableUpload failed, error: %@", _error);
    XCTAssertEqualObjects(@"iamaiosdeveloper", [_retDictionary objectForKey:@"x:cus"], "x:cus not equal");
}

- (void)testResumableUploadMedium
{
    QiniuResumableUploader *uploader = [[QiniuResumableUploader alloc] initWithToken:_token];
    uploader.delegate = self;
    
    [uploader uploadFile:_fileMedium key:[NSString stringWithFormat:@"test-medium-%@.mp4", [self timeString]] extra:nil];
    [self waitFinish];
    XCTAssertEqual(_succeed, YES, "ResumableUpload failed, error: %@", _error);
}


- (void)testResumableUploadLarge
{
    @autoreleasepool {
        
    
    QiniuResumableUploader *uploader = [[QiniuResumableUploader alloc] initWithToken:_token];
    uploader.delegate = self;
    
    [uploader uploadFile:_fileLarge key:[NSString stringWithFormat:@"test-large-%@", [self timeString]] extra:nil];
    }
    
    [self waitFinish];
    
    XCTAssertEqual(_succeed, YES, "ResumableUpload failed, error: %@", _error);
}


/*
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
 */

@end