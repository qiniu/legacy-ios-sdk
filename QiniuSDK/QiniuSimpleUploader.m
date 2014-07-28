//
//  QiniuSimpleUploader.m
//  QiniuSimpleUploader
//
//  Created by Qiniu Developers 2013
//

#import "QiniuConfig.h"
#import "QiniuSimpleUploader.h"
#import "QiniuUtils.h"
#import "ASIHTTPRequest/ASIFormDataRequest.h"
#import "GTMBase64/GTMBase64.h"
#import "JSONKit/JSONKit.h"

#define kQiniuUserAgent  @"qiniu-ios-sdk 6.0.7"

// ------------------------------------------------------------------------------------------

@implementation QiniuSimpleUploader

+ (id) uploaderWithToken:(NSString *)token {
    return [[[self alloc] initWithToken:token] autorelease];
}

// Must always override super's designated initializer.
- (id)init {
    return [self initWithToken:nil];
}

- (id)initWithToken:(NSString *)token {
    if (self = [super init]) {
        _token = [token copy];
    }
    return self;
}

- (void) dealloc
{
    self.delegate = nil;

    [_token release];
    if (_request) {
        [_request clearDelegatesAndCancel];
        [_request release];
    }
    [_filePath  release];
    [super dealloc];
}

- (void)setToken:(NSString *)token
{
    [_token autorelease];
    _token = [token copy];
}

- (id)token
{
    return _token;
}

- (void) uploadFile:(NSString *)filePath
                key:(NSString *)key
              extra:(QiniuPutExtra *)extra
{
    // If upload is called multiple times, we should cancel previous procedure.
    if (_request) {
        [_request clearDelegatesAndCancel];
        [_request release];
    }
    
    if (_filePath) {
        [_filePath  release];
    }
    _filePath = [filePath copy];
    
    // progress
    NSError *error = nil;
    _fileSize = [[[NSFileManager defaultManager] attributesOfItemAtPath:filePath error:&error] fileSize];
    if (error != nil) {
        [self.delegate uploadFailed:_filePath error:error];
        return;
    }
    _sentBytes = 0;
    
    _request = [[ASIFormDataRequest alloc] initWithURL:[NSURL URLWithString:kQiniuUpHost]];
    _request.delegate = self;
    _request.uploadProgressDelegate = self;
    
    [_request addRequestHeader:@"User-Agent" value:kQiniuUserAgent];
    
    // multipart body
    [_request addPostValue:_token forKey:@"token"];
    if (![key isEqualToString:kQiniuUndefinedKey]) {
        [_request addPostValue:key forKey:@"key"];
    }
    NSString *mimeType = nil;
    if (extra) {
        mimeType = extra.mimeType;
        if (extra.checkCrc == 1) {
            [_request addPostValue: [NSString stringWithFormat:@"%ld", extra.crc32] forKey:@"crc32"];
        }
        for (NSString *key in extra.params) {
            [_request addPostValue:[extra.params objectForKey:key] forKey:key];
        }
    }
    if (mimeType != nil) {
        [_request addFile:filePath withFileName:filePath andContentType:mimeType forKey:@"file"];
    } else {
        [_request addFile:filePath forKey:@"file"];
    }
    
    [_request startAsynchronous];
}

// Progress
- (void) request:(ASIHTTPRequest *)request didSendBytes:(long long)bytes
{
    if (!self.delegate || ![self.delegate respondsToSelector:@selector(uploadProgressUpdated:percent:)]) {
        return;
    }
    
    _sentBytes += bytes;
    
    if (_fileSize > 0) {
        double percent = (double)_sentBytes / _fileSize;
        [self.delegate uploadProgressUpdated:_filePath percent:percent];
    }
}

// Finished. This does not indicate a OK result.
- (void) requestFinished:(ASIHTTPRequest *)request
{
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
        [self reportFailure:request];
    }
}

// Failed.
- (void) requestFailed:(ASIHTTPRequest *)request
{
    [self reportFailure:request];
}

- (void) reportFailure:(ASIHTTPRequest *)request
{
    if (!self.delegate || ![self.delegate respondsToSelector:@selector(uploadFailed:error:)]) {
        return;
    }
    NSError *error = qiniuNewErrorWithRequest(request);
    [self.delegate uploadFailed:_filePath error:error];
}

@end
