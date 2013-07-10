//
//  QiniuBlockUpload.m
//  QiniuBlockUpload
//
//  Created by Qiniu Developers 2013
//

#import "QiniuBlockUpload.h"
#import "QiniuConfig.h"
#import "QiniuUtils.h"
#import "ASIHTTPRequest.h"
#import "JSONKit.h"

@implementation QiniuBlockUpload

+ (id)instanceWithToken:(NSString *)token blockIndex:(int)blockIndex blockData:(NSData *)data {
    return [[[self alloc] initWithToken:token blockIndex:blockIndex blockData:data] autorelease];
}

- (id)initWithToken:(NSString *)token blockIndex:(int)blockIndex blockData:(NSData *)blockData {
    if (self = [super init]) {
        _host = kQiniuUpHost;
        _token = [token copy];
        _blockIndex = blockIndex;
        _blockSize = [blockData length];
        _blockData = [blockData retain];
        _retryTimes = 0;
    }
    return self;
}

- (void) dealloc {
    self.delegate = nil;
    [_token release];
    [_host release];
    [_blockData release];
    if (_lastCtx) { [_lastCtx release]; }
    [super dealloc];
}

- (NSDictionary *) putChunk:(int)chunkIndex error:(NSError **) error {
    NSString *url = nil;
    if (chunkIndex == 0) { // mkblock
        url = [NSString stringWithFormat:@"%@/mkblk/%lld", kQiniuUpHost, _blockSize];
    } else { // bput
        url = [NSString stringWithFormat:@"%@/bput/%@/%d", _host, _lastCtx, chunkIndex * kQiniuChunkSize];
    }
    NSLog(@"putChunk(index:%d) ==> url:%@", chunkIndex, url);
    
    int offset = chunkIndex * kQiniuChunkSize;
    int chunkCount = ceil((double)_blockSize / kQiniuChunkSize);
    int chunkSize = (chunkIndex == chunkCount - 1) ? _blockSize - offset : kQiniuChunkSize;
    NSData *chunk = [_blockData subdataWithRange:NSMakeRange(offset, chunkSize)];
    
    ASIHTTPRequest *request = [[[ASIHTTPRequest alloc] initWithURL:[NSURL URLWithString:url]] autorelease];
    [request addRequestHeader:@"Authorization" value:[NSString stringWithFormat:@"UpToken %@", _token]];
    [request appendPostData:chunk];
    [request startSynchronous];
    
    NSDictionary *putRet = nil;
    int statusCode = [request responseStatusCode];
    if (statusCode == 200) {
        NSString *responseString = [request responseString];
        putRet = [responseString objectFromJSONString];
        NSString *ctx = [putRet objectForKey:@"ctx"];
        if (ctx) {
            if (_lastCtx) {
                [_lastCtx release];
            }
            _lastCtx = [ctx copy];
        }
        NSString *host = [putRet objectForKey:@"host"];
        if (host) {
            if (_host) {
                [_host release];
            }
            _host = [host copy];
        }
    } else {
        if (_retryTimes++ < 3) {
            return [self putChunk:chunkIndex error:error];
        } else {
            *error = qiniuNewErrorWithRequest(request);
        }
    }
    return putRet;
}

- (void) main {
    NSLog(@"uploadBlock %i started … ", _blockIndex);
    NSTimeInterval startTime = [[NSDate date] timeIntervalSince1970];
    
    @autoreleasepool {
        int chunkCount = ceil((double)_blockSize / kQiniuChunkSize);
        for (int i = 0; i < chunkCount; i++) {
            NSError *error = nil;
            NSDictionary *putRet = [self putChunk:i error:&error];
            if (error != nil) {
                [self.delegate uploadBlockFailed:_blockIndex error:error];
                return;
            }
            [self.delegate uploadBlockProgress:_blockIndex putRet:putRet];
        }
        [self.delegate uploadBlockSucceeded:_blockIndex atHost:_host context:_lastCtx];
    }
    
    NSTimeInterval endTime = [[NSDate date] timeIntervalSince1970];
    NSLog(@"uploadBlock %i completed. (size:%lld time:%ldsecs host:%@ )",
          _blockIndex, _blockSize, (long)(endTime - startTime), _host);
}

@end
