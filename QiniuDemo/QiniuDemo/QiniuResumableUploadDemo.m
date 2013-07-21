//
//  QiniuResumableUploadDemo.m
//  QiniuDemo
//
//  Created by Qiniu Developers 2013
//

#import "QiniuResumableUploadDemo.h"
#import "QiniuPutPolicy.h"
#import "../../QiniuSDK/QiniuBlkputRet.h"
#import "../../QiniuSDK/QiniuPutExtra.h"
#import "../../QiniuSDK/QiniuResumableUploader.h"

#define defaultBlockSize (1 << 22)

static NSString *QiniuAccessKey = @"<Please specify your access key>";
static NSString *QiniuSecretKey = @"<Please specify your secret key>";
static NSString *QiniuBucketName = @"<Please specify your bucket name>";

@implementation QiniuResumableUploadDemo

- (id) initWithFile:(NSString *)filePath persistenceDir:(NSString *)dir {
    _filePath = filePath;
    _persistenceDir = dir;
    
    // token
    QiniuAccessKey = @"dbsrtUEWFt_HMlY59qw5KqaydbvML1zxtxsvioUX";
    QiniuSecretKey = @"EZUwWLGLfbq0y94SLteofzzqKc60Dxg5kc1Rv2ct";
    QiniuBucketName = @"shijy";
    QiniuPutPolicy *policy = [[QiniuPutPolicy new] autorelease];
    policy.expires = 36000;
    policy.scope = QiniuBucketName;
    _token = [policy makeToken:QiniuAccessKey secretKey:QiniuSecretKey];
    
    // block count
    NSError *error = nil;
    long long fileSize = [[[NSFileManager defaultManager] attributesOfItemAtPath:filePath error:&error] fileSize];
    if (error) {
        return nil;
    }
    _blockCount = ceil((double)fileSize / defaultBlockSize);
    
    // init progresses
    _progresses = [NSMutableArray arrayWithCapacity:_blockCount];
    for (int i = 0; i < _blockCount; i++) {
        [_progresses addObject:[[QiniuBlkputRet alloc] init]];
    }
    
    // read persistence files to rebuild progresses
    for (int i = 0; i < _blockCount; i++) {
        NSData *progressData = [NSData dataWithContentsOfFile:[NSString stringWithFormat:@"%@/block_%d.txt", dir, i]];
        if (progressData != nil) {
            QiniuBlkputRet *progress = [NSKeyedUnarchiver unarchiveObjectWithData:progressData];
            [_progresses replaceObjectAtIndex:i withObject:progress];
        }
    }
    return [super init];
}

- (void)uploadProgressUpdated:(NSString *)theFilePath percent:(float)percent
{
    NSLog(@"Progress Updated: %@ - %f", theFilePath, percent);
}

- (void)uploadSucceeded:(NSString *)theFilePath ret:(NSDictionary *)ret
{
    NSLog(@"Upload Succeeded: %@ - Ret: %@", theFilePath, ret);
}

- (void)uploadFailed:(NSString *)theFilePath error:(NSError *)error
{
    NSLog(@"Upload Failed: %@ - Reason: %@", theFilePath, error);
}

- (void) resumalbleUpload:(NSString *)key {
    QiniuResumableUploader *uploader = [QiniuResumableUploader instanceWithToken: _token];
    uploader.delegate = self;
    QiniuRioPutExtra *params = [[[QiniuRioPutExtra alloc] init] autorelease];
    params.bucket = QiniuBucketName;
    params.progresses = _progresses;
    
    // block progress persistence
    params.notify = ^(int blockIndex, int blockSize, QiniuBlkputRet* ret) {
        NSLog(@"notify for data persistence, blockIndex:%d, blockSize:%d, offset:%d ctx:%@",
              blockIndex, blockSize, (unsigned int)ret.offset, ret.ctx);
        NSData *progressData = [NSKeyedArchiver archivedDataWithRootObject:ret];
        [progressData writeToFile:[NSString stringWithFormat:@"%@/block_%d.txt", _persistenceDir, blockIndex] atomically:true];
    };
    
    params.notifyErr = ^(int blockIndex, int blockSize, NSError* error) {
        NSLog(@"notify for block upload failed, blockIndex:%d, blockSize:%d, error:%@",
              blockIndex, blockSize, error);
    };
    
    [uploader uploadFile:_filePath key:key params:params];
}

@end
