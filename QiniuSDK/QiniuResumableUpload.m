//
//  QiniuResumableUpload.m
//  QiniuResumableUpload
//
//  Created by Qiniu Developers 2013
//

#import "JSONKit.h"
#import "QiniuConfig.h"
#import "QiniuUtils.h"
#import "QiniuBlockUpload.h"
#import "QiniuResumableUpload.h"

@implementation QiniuResumableUpload

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
        _host = kQiniuUpHost;
    }
    return self;
}

void freeid(id obj) {
    if (obj != nil) { [obj release]; }
}

- (void)dealloc {
    freeid(_bucket);
    freeid(_key);
    freeid(_host);
    freeid(_extraParams);
    freeid(_filePath);
    freeid(_mappedFile);
    freeid(_taskQueue);
    freeid(_blockSentBytes);
    freeid(_blockCtxs);
    [super dealloc];
}

- (void) makeFile {
    NSString *encodedURI = urlsafeBase64String([NSString stringWithFormat:@"%@:%@", _bucket, _key]);
    NSMutableString *url = [NSMutableString stringWithFormat:@"%@/rs-mkfile/%@/fsize/%lld", _host, encodedURI, _fileSize];
    NSLog(@"makeFile ==> url:%@", url);
    
    // All of following fields are optional.
    if (_extraParams) {
        NSString *mimeType = [_extraParams objectForKey:@"mimeType"];
        if (mimeType) {
            [url appendString:@"/mimeType/"];
            [url appendString:urlsafeBase64String(mimeType)];
        }
        NSDictionary *params = [_extraParams objectForKey:@"params"];
        if (params) {
            [url appendString:@"/params/"];
            [url appendString:urlsafeBase64String(urlParamsString(params))];
        }
    }
    
    ASIHTTPRequest *request = [[[ASIHTTPRequest alloc] initWithURL:[NSURL URLWithString:url]] autorelease];
    
    [request addRequestHeader:@"Authorization" value:[NSString stringWithFormat:@"UpToken %@", _token]];
    [request addRequestHeader:@"Content-Type" value:@"text/plain"];
    
    NSMutableString *ctxArray = [NSMutableString string];
    for (int i = 0; i < _blockCount; i++) {
        [ctxArray appendString:[_blockCtxs objectAtIndex:i]];
        if (i != _blockCount - 1) {
            [ctxArray appendString:@","]; // Add separator
        }
    }
    NSData *data = [ctxArray dataUsingEncoding:NSUTF8StringEncoding];
    
    [request appendPostData:data];
    [request startSynchronous];
    
    int statusCode = [request responseStatusCode];
    if (statusCode == 200) { // Success!
        if (self.delegate && [self.delegate respondsToSelector:@selector(uploadProgressUpdated:percent:)]) {
            [self.delegate uploadProgressUpdated:_filePath
                                         percent:1.0]; // Ensure a 100% progress message is sent.
        }
        if (self.delegate && [self.delegate respondsToSelector:@selector(uploadSucceeded:ret:)]) {
            NSString *responseString = [request responseString];
            if (responseString) {
                NSDictionary *dic = [responseString objectFromJSONString];
                [self.delegate uploadSucceeded:_filePath ret:dic];
            }
        }
    } else { // Server returns an error code.
        NSError *error = qiniuNewErrorWithRequest(request);
        [self.delegate uploadFailed:_filePath error:error];
    }
}

// ------------------------------------------------------------------------------------
// @protocol QiniuBlockUploadDelegate

- (void) uploadBlockProgress:(int)blockIndex putRet:(NSDictionary *)putRet {
    NSNumber *newOffset = [putRet objectForKey:@"offset"];
    NSNumber *oldOffset = [_blockSentBytes objectAtIndex:blockIndex];
    long long bytesSent = [newOffset longLongValue] - [oldOffset longLongValue];
    _totalBytesSent += bytesSent;
    double percent = (double)_totalBytesSent / _fileSize;
    [self.delegate uploadProgressUpdated:_filePath percent:percent];
    
    [_blockSentBytes replaceObjectAtIndex:blockIndex withObject:newOffset];
}

- (void) uploadBlockSucceeded:(int)blockIndex atHost:(NSString *)host context:(NSString *)context {
    if (_host) {
        [_host release];
    }
    _host = [host copy];
    
    [_blockCtxs replaceObjectAtIndex:blockIndex withObject:context];
    _completedBlockCount++;
    if (_completedBlockCount == _blockCount) { // All blocks have been uploaded.
        [self makeFile];
    }
}

- (void) uploadBlockFailed:(int)blockIndex error:(NSError *)error {
    [_taskQueue cancelAllOperations];
    [self.delegate uploadFailed:_filePath error:error];
}

- (void) initEnvWithFile:(NSString *)filePath
                  bucket:(NSString *)bucket
                     key:(NSString *)key
             extraParams:(NSDictionary *)extraParams {
    
    if (_bucket) {
        [_bucket release];
    }
    _bucket = [bucket copy];
    if (_key) {
        [_key release];
    }
    _key = [key copy];
    if (_filePath) {
        [_filePath release];
    }
    _filePath = [filePath copy];
    if (_extraParams) {
        [_extraParams release];
    }
    _extraParams = [extraParams retain];
    
    if (_taskQueue) {
        [_taskQueue cancelAllOperations];
        [_taskQueue release];
    }
    _taskQueue = [[NSOperationQueue alloc] init];
    [_taskQueue setMaxConcurrentOperationCount:kQiniuMaxConcurrentUploads];
    
    NSError *error = nil;
    _fileSize = [[[NSFileManager defaultManager] attributesOfItemAtPath:filePath error:&error] fileSize];
    if (error) {
        [self.delegate uploadFailed:_filePath error:error];
    }
    
    if (_mappedFile) {
        [_mappedFile release];
    }
    _mappedFile = [[NSData alloc] initWithContentsOfFile:filePath
                                                         options:NSDataReadingMappedIfSafe
                                                           error:&error];
    if (error) {
        [self.delegate uploadFailed:_filePath error:error];
        return;
    }
    
    _blockCount = ceil((double)_fileSize / kQiniuBlockSize);
    if (_blockSentBytes) {
        [_blockSentBytes release];
    }
    _blockSentBytes = [[NSMutableArray alloc] initWithCapacity:_blockCount];
    
    if (_blockCtxs) {
        [_blockCtxs release];
    }
    _blockCtxs = [[NSMutableArray alloc] initWithCapacity:_blockCount];
    
    for (int i = 0; i < _blockCount; i++) {
        [_blockSentBytes addObject:[NSNumber numberWithLongLong:0]];
        [_blockCtxs addObject:@"<CtxPlaceholder>"];
    }
    _completedBlockCount = 0;
    _totalBytesSent = 0;
}

- (void) uploadFile:(NSString *)filePath
                key:(NSString *)key
             bucket:(NSString *)bucket
        extraParams:(NSDictionary *)extraParams {
    
    [self initEnvWithFile:filePath bucket:bucket key:key extraParams:extraParams];
    
    for (int blockIndex = 0; blockIndex < _blockCount; blockIndex++) {
        int offset = blockIndex * kQiniuBlockSize;
        int blockSize = (blockIndex == _blockCount - 1) ? _fileSize - offset : kQiniuBlockSize;
        NSData *blockData = [_mappedFile subdataWithRange:NSMakeRange(offset, blockSize)];
        QiniuBlockUpload *task = [QiniuBlockUpload instanceWithToken:self.token blockIndex:blockIndex blockData:blockData];
        task.delegate = self;
        [_taskQueue addOperation:task];
    }
}

@end
