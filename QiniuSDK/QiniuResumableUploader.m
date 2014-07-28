//
//  QiniuResumableUpload.m
//  QiniuResumableUpload
//
//  Created by Qiniu Developers 2013
//

#import "JSONKit.h"
#import "QiniuConfig.h"
#import "QiniuUtils.h"
#import "QiniuBlockUploader.h"
#import "QiniuResumableUploader.h"

#define defaultBlockSize    (1 << 22)
#define defaultChunkSize	(256 * 1024) // 256k
#define defaultTryTimes     3
#define defaultWorkers      4

// --------------------------------------------------
// QiniuResumableUploader

@implementation QiniuResumableUploader

+ (id) instanceWithToken:(NSString *)token
{
    return [[[self alloc] initWithToken:token] autorelease];
}

- (id)init {
    return [self initWithToken:nil];
}

- (id)initWithToken:(NSString *)token {
    if (self = [super init]) {
        self.token = token;
    }
    return self;
}

void freeid(id obj) {
    if (obj != nil) { [obj release]; }
}

- (void)dealloc {
    freeid(_bucket);
    freeid(_key);
    freeid(_params);
    freeid(_filePath);
    freeid(_mappedFile);
    freeid(_taskQueue);
    freeid(_blockSentBytes);
    freeid(_blockCtxs);
    [super dealloc];
}

- (void) makeFile {
    NSString *encodedURI = urlsafeBase64String([NSString stringWithFormat:@"%@:%@", _bucket, _key]);
    NSMutableString *url = [NSMutableString stringWithFormat:@"%@/rs-mkfile/%@/fsize/%lld", kQiniuUpHost, encodedURI, _fileSize];
    NSLog(@"makeFile ==> url:%@", url);
    
    // All of following fields are optional.
    if (_params) {
        if (_params.mimeType) {
            [url appendString:@"/mimeType/"];
            [url appendString:urlsafeBase64String(_params.mimeType)];
        }
        if (_params.callbackParams) {
            [url appendString:@"/params/"];
            [url appendString:urlsafeBase64String(_params.callbackParams)];
        }
    }
    
    ASIHTTPRequest *request = [[[ASIHTTPRequest alloc] initWithURL:[NSURL URLWithString:url]] autorelease];
    
    [request addRequestHeader:@"Authorization" value:[NSString stringWithFormat:@"UpToken %@", _token]];
    [request addRequestHeader:@"Content-Type" value:@"text/plain"];
    [request setUserAgentString:qiniuUserAgent()];
    
    NSMutableString *ctxArray = [NSMutableString string];
    for (int i = 0; i < _blockCount; i++) {
        [ctxArray appendString:[_blockCtxs objectAtIndex:i]];
        if (i != _blockCount - 1) {
            [ctxArray appendString:@","]; // Add separator
        }
    }
    //NSLog(@"mkfile ==> ctxs:%@", ctxArray);
    NSData *data = [ctxArray dataUsingEncoding:NSUTF8StringEncoding];
    
    [request appendPostData:data];
    [request startSynchronous];
    
    int statusCode = [request responseStatusCode];
    if (statusCode == 200) { // Success!
        if (self.delegate && [self.delegate respondsToSelector:@selector(uploadProgressUpdated:percent:)]) {
            [self.delegate uploadProgressUpdated:_filePath
                                         percent:1.0]; // Ensure a 100% progress message is sent.
        }
        if (self.delegate) {
            NSString *responseString = [request responseString];
            if (responseString) {
                NSDictionary *dic = [responseString objectFromJSONString];
                [self.delegate uploadSucceeded:_filePath ret:dic];
            }
        }
    } else {
        NSError *error = qiniuNewErrorWithRequest(request);
        [self.delegate uploadFailed:_filePath error:error];
    }
}

// ------------------------------------------------------------------------------------
// @protocol QiniuBlockUploadDelegate

- (void) uploadBlockProgress:(int)blockIndex blockSize:(int)blockSize putRet:(QiniuBlkputRet *)putRet {
    
    NSNumber *prevOffset = [_blockSentBytes objectAtIndex:blockIndex];
    
    long long bytesSent = putRet.offset - [prevOffset longLongValue];
    double percent;
    @synchronized (self) {
        _totalBytesSent += bytesSent;
        percent = (double)_totalBytesSent / _fileSize;
    }
    
    if (percent >= 0.95) {
        percent = 0.95;
    }
    [self.delegate uploadProgressUpdated:_filePath percent:percent];
    
    [_blockSentBytes replaceObjectAtIndex:blockIndex withObject:[NSNumber numberWithLongLong:putRet.offset]];
    [_blockCtxs replaceObjectAtIndex:blockIndex withObject:putRet.ctx];
}

- (void) uploadBlockSucceeded:(int)blockIndex blockSize:(int)blockSize {
    _completedBlockCount++;
    if (_completedBlockCount == _blockCount) { // All blocks have been uploaded.
        [self makeFile];
    }
}

- (void) uploadBlockFailed:(int)blockIndex blockSize:(int)blockSize error:(NSError *)error {
    [_taskQueue cancelAllOperations];
    [self.delegate uploadFailed:_filePath error:error];
}

- (void) initEnvWithFile:(NSString *)filePath
                     key:(NSString *)key
                  params:(QiniuRioPutExtra *)params {
    
    if (params.chunkSize == 0) {
        params.chunkSize = defaultChunkSize;
    }
    if (params.tryTimes == 0) {
        params.tryTimes = defaultTryTimes;
    }
    if (params.concurrentNum == 0) {
        params.concurrentNum = defaultWorkers;
    }
    if (params.notify == nil) {
        params.notify = ^(int blockIndex, int blockSize, QiniuBlkputRet* ret) {};
    }
    if (params.notifyErr == nil) {
        params.notifyErr = ^(int blockIndex, int blockSize, NSError* error) {};
    }
    
    NSError *error = nil;
    _fileSize = [[[NSFileManager defaultManager] attributesOfItemAtPath:filePath error:&error] fileSize];
    if (error) {
        [self.delegate uploadFailed:filePath error:error];
    }
    
    if (_mappedFile) {
        [_mappedFile release];
    }
    _mappedFile = [[NSData alloc] initWithContentsOfFile:filePath
                                                 options:NSDataReadingMappedIfSafe
                                                   error:&error];
    if (error) {
        [self.delegate uploadFailed:filePath error:error];
        return;
    }
    
    _blockCount = ceil((double)_fileSize / defaultBlockSize);
    
    if (params.progresses == nil) {
        params.progresses = [NSMutableArray arrayWithCapacity:_blockCount];
        for (int i = 0; i < _blockCount; i++) {
            [params.progresses addObject:[[QiniuBlkputRet alloc] init]];
        }
    } else if ([params.progresses count] != _blockCount) {
        [self.delegate uploadFailed:filePath error:qiniuNewError(400, @"invalid put progress")];
        return;
    }
    
    if (_bucket) {
        [_bucket release];
    }
    _bucket = [params.bucket copy];
    if (_key) {
        [_key release];
    }
    _key = [key copy];
    if (_filePath) {
        [_filePath release];
    }
    _filePath = [filePath copy];
    if (_params) {
        [_params release];
    }
    _params = [params retain];
    
    if (_taskQueue) {
        [_taskQueue cancelAllOperations];
        [_taskQueue release];
    }
    _taskQueue = [[NSOperationQueue alloc] init];
    [_taskQueue setMaxConcurrentOperationCount:params.concurrentNum];
    
    if (_blockSentBytes) {
        [_blockSentBytes release];
    }
    _blockSentBytes = [[NSMutableArray alloc] initWithCapacity:_blockCount];
    
    if (_blockCtxs) {
        [_blockCtxs release];
    }
    _blockCtxs = [[NSMutableArray alloc] initWithCapacity:_blockCount];
    
    _totalBytesSent = 0;
    for (int i = 0; i < _blockCount; i++) {
        QiniuBlkputRet *progress = [_params.progresses objectAtIndex:i];
        [_blockSentBytes addObject:[NSNumber numberWithLongLong:progress.offset]];
        [_blockCtxs addObject:progress.ctx];
        _totalBytesSent += progress.offset;
    }
    _completedBlockCount = 0;
}

- (void) uploadFile:(NSString *)filePath
                key:(NSString *)key
             params:(QiniuRioPutExtra *)params {
    
    [self initEnvWithFile:filePath key:key params:params];
    
    for (int blockIndex = 0; blockIndex < _blockCount; blockIndex++) {
        int offset = blockIndex * defaultBlockSize;
        int blockSize = (blockIndex == _blockCount - 1) ? _fileSize - offset : defaultBlockSize;
        NSData *blockData = [_mappedFile subdataWithRange:NSMakeRange(offset, blockSize)];
        QiniuBlkputRet *progress = (QiniuBlkputRet *)params.progresses[blockIndex];
        QiniuBlockUploader *task = [[[QiniuBlockUploader alloc] initWithToken:self.token
                                                          blockIndex:blockIndex
                                                           blockData:blockData
                                                             progress:progress
                                                               params:params] autorelease];
        task.delegate = self;
        [_taskQueue addOperation:task];
    }
}

- (void) stopUpload {
    if (_taskQueue) {
        [_taskQueue cancelAllOperations];
        [_taskQueue release];
        _taskQueue = nil;
    }
}

@end
