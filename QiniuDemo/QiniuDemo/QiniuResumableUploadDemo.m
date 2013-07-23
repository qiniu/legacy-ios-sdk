//
//  QiniuResumableUploadDemo.m
//  QiniuDemo
//
//  Created by Qiniu Developers 2013
//

#import "QiniuResumableUploadDemo.h"
#import "../../QiniuSDK/QiniuBlkputRet.h"
#import "../../QiniuSDK/QiniuPutExtra.h"
#import "../../QiniuSDK/QiniuResumableUploader.h"

#define defaultBlockSize (1 << 22)

@implementation QiniuResumableUploadDemo

- (id) initWithToken:(NSString *)token {
    if (self = [super init]) {
        self.token = token;
    }
    return self;
}

- (void)dealloc {
    [_filePath release];
    [_persistenceDir release];
    [_progresses release];
    [_uploader release];
    [super dealloc];
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

- (void) initEnv:(NSString *)filePath persistenceDir:(NSString *)dir error:(NSError **)error{
    if (_filePath) {
        [_filePath release];
    }
    _filePath = [filePath copy];
    if (_persistenceDir) {
        [_persistenceDir release];
    }
    _persistenceDir = [dir copy];
    
    // block count
    long long fileSize = [[[NSFileManager defaultManager] attributesOfItemAtPath:filePath error:error] fileSize];
    if (*error) {
        return;
    }
    int blockCount = ceil((double)fileSize / defaultBlockSize);
    
    // init progresses
    if (_progresses) {
        [_progresses release];
    }
    _progresses = [[NSMutableArray arrayWithCapacity:blockCount] retain];
    for (int i = 0; i < blockCount; i++) {
        [_progresses addObject:[[QiniuBlkputRet alloc] init]];
    }
    
    // read persistence files to rebuild progresses
    for (int i = 0; i < blockCount; i++) {
        NSData *progressData = [NSData dataWithContentsOfFile:[NSString stringWithFormat:@"%@/block_%d.txt", dir, i]];
        if (progressData != nil) {
            QiniuBlkputRet *progress = [NSKeyedUnarchiver unarchiveObjectWithData:progressData];
            [_progresses replaceObjectAtIndex:i withObject:progress];
        }
    }
}

- (void) resumalbleUploadFile:(NSString *)filePath persistenceDir:(NSString *)dir bucket:(NSString *)bucket key:(NSString *)key {
    NSError *error = nil;
    [self initEnv:filePath persistenceDir:dir error:&error];
    if (error) {
        NSLog(@"resumalbleUploadFile failed: %@", error);
        return;
    }
    QiniuRioPutExtra *params = [[[QiniuRioPutExtra alloc] init] autorelease];
    params.bucket = bucket;
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
    
    _uploader = [[QiniuResumableUploader alloc] initWithToken: self.token];
    _uploader.delegate = self;
    [_uploader uploadFile:_filePath key:key params:params];
}

- (void) stopUpload {
    [_uploader stopUpload];
    [_uploader release];
}

@end
