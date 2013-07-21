//
//  QiniuBlockUpload.m
//  QiniuBlockUpload
//
//  Created by Qiniu Developers 2013
//

#import "QiniuBlockUploader.h"
#import "QiniuConfig.h"
#import "QiniuUtils.h"
#import "ASIHTTPRequest.h"
#import "JSONKit.h"
#import <zlib.h>

#define InvalidCrc  406
#define InvalidCtx  701

@implementation QiniuBlockUploader

- (id)initWithToken:(NSString *)token
         blockIndex:(int)blockIndex
          blockData:(NSData *)blockData
           progress:(QiniuBlkputRet *)progress
             params:(QiniuRioPutExtra *)params {
    
    if (self = [super init]) {
        _token = [token copy];
        _blockIndex = blockIndex;
        _blockSize = [blockData length];
        _blockData = [blockData retain];
        _progress = [progress retain];
        _params = [params retain];
    }
    return self;
}

- (void) dealloc {
    [_token release];
    [_blockData release];
    [_progress release];
    [_params release];
    [super dealloc];
}

- (void) postChunk:(NSData *)chunk
               url:(NSString *)url
    updateProgress:(QiniuBlkputRet *)progress
             error:(NSError **) error {
    
    ASIHTTPRequest *request = [[[ASIHTTPRequest alloc] initWithURL:[NSURL URLWithString:url]] autorelease];
    [request addRequestHeader:@"Authorization" value:[NSString stringWithFormat:@"UpToken %@", _token]];
    [request appendPostData:chunk];
    [request startSynchronous];
    
    int statusCode = [request responseStatusCode];
    if (statusCode == 200) {
        NSString *jsonStr = [request responseString];
        NSDictionary *putRet = [jsonStr objectFromJSONString];
        progress.ctx = [putRet objectForKey:@"ctx"];
        progress.host = [putRet objectForKey:@"host"];
        progress.checksum = [putRet objectForKey:@"checksum"];
        progress.crc32 = [[putRet objectForKey:@"crc32"] intValue];
        progress.offset = [[putRet objectForKey:@"offset"] intValue];
        *error = nil;
    } else {
        *error = qiniuNewErrorWithRequest(request);
    }
}

- (void) resumableBlockUpload:(NSError **)error {
    UInt32 chunkSize = _params.chunkSize;
    UInt32 bodySize = 0;
    
    if (_progress.ctx == nil || [_progress.ctx isEqualToString:@""]) {
        if (chunkSize < _blockSize) {
            bodySize = chunkSize;
        } else {
            bodySize = _blockSize;
        }
        NSData *body = [_blockData subdataWithRange:NSMakeRange(0, bodySize)];
        
        NSString *url = [NSString stringWithFormat:@"%@/mkblk/%lld", kQiniuUpHost, _blockSize];
        NSLog(@"url:%@", url);
        [self postChunk:body url:url updateProgress:_progress error:error];
        if (*error) {
            return;
        }
        
        uLong crcVal = crc32(0L, Z_NULL, 0);
        crcVal = crc32(crcVal, [body bytes], [body length]);
        if (_progress.crc32 != crcVal || _progress.offset != bodySize) {
            *error = qiniuNewError(InvalidCrc, @"unmatched checksum");
            _progress.ctx = @""; // reset
            return;
        }
        
        _params.notify(_blockIndex, _blockSize, _progress);
        [self.delegate uploadBlockProgress:_blockIndex blockSize:_blockSize putRet:_progress];
    }
    
    while (_progress.offset < _blockSize) {
        if (chunkSize < _blockSize - (_progress.offset)) {
            bodySize = chunkSize;
        } else {
            bodySize = _blockSize - (_progress.offset);
        }
        NSData *body = [_blockData subdataWithRange:NSMakeRange(_progress.offset, bodySize)];
        
        for (int i = 0; i < _params.tryTimes; i++) {
            NSString *url = [NSString stringWithFormat:@"%@/bput/%@/%d", _progress.host, _progress.ctx, _progress.offset];
            NSLog(@"url:%@", url);
            [self postChunk:body url:url updateProgress:_progress error:error];
            if (*error == nil) {
                uLong crcVal = crc32(0L, Z_NULL, 0);
                crcVal = crc32(crcVal, [body bytes], [body length]);
                if (_progress.crc32 == crcVal) {
                    _params.notify(_blockIndex, _blockSize, _progress);
                    [self.delegate uploadBlockProgress:_blockIndex blockSize:_blockSize putRet:_progress];
                    break;
                }
                *error = qiniuNewError(InvalidCrc, @"unmatched checksum");
            }
            if ([*error code] == InvalidCtx || [*error code] == InvalidCrc) {
                _progress.ctx = @""; // reset
                NSLog(@"BlockUpload: invalid ctx or crc, please retry");
                return;
            }
        }
    }
}

-(void) main {
    NSLog(@"uploadBlock %i started … ", _blockIndex);
    NSTimeInterval startTime = [[NSDate date] timeIntervalSince1970];
    
    @autoreleasepool {
        NSError *error = nil;
        for (int i = 0; i < _params.tryTimes; i++) {
            error = nil;
            [self resumableBlockUpload:&error];
            if (error == nil) { // success
                [self.delegate uploadBlockSucceeded:_blockIndex blockSize:_blockSize];
                break;
            }
        }
        if (error != nil) {
            NSLog(@"uploadBlock %i failed, error:%@", _blockIndex, error);
            _params.notifyErr(_blockIndex, _blockSize, error);
            [self.delegate uploadBlockFailed:_blockIndex blockSize:_blockSize error:error];
        }
    }

    NSTimeInterval endTime = [[NSDate date] timeIntervalSince1970];
    NSLog(@"uploadBlock %i completed. (size:%lld time:%ldsecs )",
          _blockIndex, _blockSize, (long)(endTime - startTime));
}

@end
