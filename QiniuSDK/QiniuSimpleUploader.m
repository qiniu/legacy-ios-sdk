//
//  QiniuSimpleUploader.m
//  QiniuSimpleUploader
//
//  Created by Qiniu Developers on 12-11-14.
//  Copyright (c) 2012 Shanghai Qiniu Information Technologies Co., Ltd. All rights reserved.
//

#import "QiniuConfig.h"
#import "QiniuSimpleUploader.h"
#import "ASIHTTPRequest/ASIFormDataRequest.h"
#import "GTMBase64/GTMBase64.h"
#import "JSONKit/JSONKit.h"

#define kErrorDomain @"QiniuSimpleUploader"
#define kFilePathKey @"filePath"
#define kHashKey @"hash"
#define kErrorKey @"error"
#define kXlogKey @"X-Log"
#define kXreqidKey @"X-Reqid"
#define kFileSizeKey @"fileSize"
#define kKeyKey @"key"
#define kBucketKey @"bucket"
#define kExtraParamsKey @"extraParams"

NSString *urlsafeBase64String(NSString *sourceString)
{
    return [GTMBase64 stringByWebSafeEncodingData:[sourceString dataUsingEncoding:NSUTF8StringEncoding] padded:TRUE];
}

// Convert NSDictionary to strings like: key1=value1&key2=value2&key3=value3 ...
NSString *urlParamsString(NSDictionary *dic)
{
    if (!dic) {
        return nil;
    }
    
    NSMutableString *callbackParamsStr = [NSMutableString string];
    for (NSString *key in [dic allKeys]) {
        if ([callbackParamsStr length] > 0) {
            [callbackParamsStr appendString:@"&"];
        }
        [callbackParamsStr appendFormat:@"%@=%@", key, [dic objectForKey:key]];
    }
    return callbackParamsStr;
}

// ------------------------------------------------------------------------------------------

@implementation QiniuSimpleUploader

@synthesize delegate;

+ (id) uploaderWithToken:(NSString *)token
{
    return [[[self alloc] initWithToken:token] autorelease];
}

// Must always override super's designated initializer.
- (id)init {
    return [self initWithToken:nil];
}

- (id)initWithToken:(NSString *)token
{
    if (self = [super init]) {
        _token = [token copy];
        _request = nil;
    }
    return self;
}

- (void) dealloc
{
    [_token autorelease];
    if (_request) {
        [_request clearDelegatesAndCancel];
        [_request release];
    }
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

- (void) upload:(NSString *)filePath
         bucket:(NSString *)bucket
            key:(NSString *)key
    extraParams:(NSDictionary *)extraParams
{
    // If upload is called multiple times, we should cancel previous procedure.
    if (_request) {
        [_request clearDelegatesAndCancel];
        [_request release];
    }
    
    NSString *url = [NSString stringWithFormat:@"%@/upload", kUpHost];
    
    NSString *encodedEntry = urlsafeBase64String([NSString stringWithFormat:@"%@:%@", bucket, key]);

    // Prepare POST body fields.
    NSMutableString *action = [NSMutableString stringWithFormat:@"/rs-put/%@", encodedEntry];
    
    // All of following fields are optional.
    if (extraParams) {
        NSObject *mimeTypeObj = [extraParams objectForKey:kMimeTypeKey];
        if (mimeTypeObj) {
            [action appendString:@"/mimeType/"];
            [action appendString:urlsafeBase64String((NSString *)mimeTypeObj)];
        }
        
        NSObject *customMetaObj = [extraParams objectForKey:kCustomMetaKey];
        if (customMetaObj) {
            [action appendString:@"/meta/"];
            [action appendString:urlsafeBase64String((NSString *)customMetaObj)];
        }
        
        NSObject *crc32Obj = [extraParams objectForKey:kCrc32Key];
        if (crc32Obj) {
            [action appendString:@"/crc32/"];
            [action appendString:(NSString *)crc32Obj];
        }

        NSObject *rotateObj = [extraParams objectForKey:kRotateKey];
        if (rotateObj) {
            [action appendString:@"/rotate/"];
            [action appendString:(NSString *)rotateObj];
        }
    }
    
    _request = [[ASIFormDataRequest requestWithURL:[NSURL URLWithString:url]] retain];
    _request.delegate = self;
    _request.uploadProgressDelegate = self;
    
    [_request addPostValue:action forKey:@"action"];
    [_request addFile:filePath forKey:@"file"];
    
    if (_token) {
        [_request addPostValue:_token forKey:@"auth"];
    }
    
    if (extraParams) {
        NSObject *callbackParamsObj = [extraParams objectForKey:kCallbackParamsKey];
        if (callbackParamsObj != nil) {
            NSDictionary *callbackParams = (NSDictionary *)callbackParamsObj;
            
            [_request addPostValue:urlParamsString(callbackParams) forKey:@"params"];
        }
    }
    
    NSNumber* fileSizeNumber = [[[NSFileManager defaultManager] attributesOfItemAtPath:filePath error:nil] objectForKey:NSFileSize];
    
    NSDictionary *context = [NSDictionary dictionaryWithObjectsAndKeys:filePath, kFilePathKey,
                             fileSizeNumber, kFileSizeKey,
                             bucket, kBucketKey,
                             key, kKeyKey,
                             extraParams, kExtraParamsKey, // Might be nil.
                             nil];
    
    [_request setUserInfo:context];
    
    [_request startAsynchronous];
}

// Progress
- (void) request:(ASIHTTPRequest *)request didSendBytes:(long long)bytes
{
    if (!request) {
        return;
    }
    
    _sentBytes += bytes;
    
    if (delegate && [delegate respondsToSelector:@selector(uploadProgressUpdated:percent:)]) {
        NSObject *context = [request userInfo];
        if (context) {
            NSDictionary *contextDic = (NSDictionary *)context;
            NSString *filePath = (NSString *)[contextDic objectForKey:kFilePathKey];
            if (filePath) {
                long long fileSize = [((NSNumber *)[contextDic objectForKey:kFileSizeKey]) longLongValue];
                if (fileSize > 0) {
                    float percent = (float)((double)_sentBytes / fileSize);
                    [delegate uploadProgressUpdated:filePath percent:percent];
                }
            }
        }
    }
}

// Finished. This does not indicate a OK result.
- (void) requestFinished:(ASIHTTPRequest *)request
{
    if (!request) {
        [self reportFailure:nil]; // Make sure a failure message is sent.
        return;
    }
    
    NSString *filePath = [[request userInfo] objectForKey:kFilePathKey];

    int statusCode = [request responseStatusCode];
    if (statusCode / 100 == 2) { // Success!
        
        if (delegate && [delegate respondsToSelector:@selector(uploadProgressUpdated:percent:)]) {
            [delegate uploadProgressUpdated:filePath percent:1.0]; // Ensure a 100% progress message is sent.
        }
            
        if (delegate && [delegate respondsToSelector:@selector(uploadSucceeded:hash:)]) {
            NSString *responseString = [request responseString];
            NSString *hash = nil;
            if (responseString) {
                NSDictionary *dic = [responseString objectFromJSONString];
                
                NSObject *hashObj = [dic objectForKey:kHashKey];
                if (hashObj) {
                    hash = (NSString *)hashObj;
                }
            }
            [delegate uploadSucceeded:filePath hash:hash]; // No matter hash is nil or not, send this event.
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
    if (!delegate || ![delegate respondsToSelector:@selector(uploadFailed:error:)]) {
        return;
    }
    
    NSString *filePath = @"<UnknownPath>";
    NSDictionary *dic = nil;
    NSError *httpError = nil;
    
    if (request) {
        NSString *responseString = [request responseString];
        if (responseString) {
            dic = [responseString objectFromJSONString];
        }
        NSObject *context = [request userInfo];
        if (context) {
            NSDictionary *contextDic = (NSDictionary *)context;
            filePath = (NSString *)[contextDic objectForKey:kFilePathKey];
        }
        
        httpError = [request error];
    }
    
    int errorCode = [request responseStatusCode];
    NSString *errorDescription = nil;
    if (dic) { // Check if there is response content.
        NSObject *errorObj = [dic objectForKey:kErrorKey];
        if (errorObj) {
            errorDescription = [(NSString *)errorObj copy];
        }
    }
    if (errorDescription == nil && httpError) { // No response, then try to retrieve the HTTP error info.
        errorCode = [httpError code];
        errorDescription = [httpError localizedDescription];
    }
    
    NSMutableDictionary *userInfo = [NSMutableDictionary dictionary];
    if (errorDescription) {
        [userInfo setObject:errorDescription forKey:kErrorKey];
    }
    
    NSDictionary *respHeaders = [request responseHeaders];
    if (respHeaders) {
        // TEST ONLY CODE.
        //for (id key in [respHeaders allKeys]) {
        //    NSLog(@"HEADER[%@]:%@", key, [respHeaders objectForKey:key]);
        //}
        
        NSObject *xlogObj = [respHeaders objectForKey:kXlogKey];
        if (xlogObj) {
            [userInfo setObject:xlogObj forKey:kXlogKey];
        }
        NSObject *xreqidObj = [respHeaders objectForKey:kXreqidKey];
        if (xreqidObj) {
            [userInfo setObject:xreqidObj forKey:kXreqidKey];
        }
    }
    
    NSError *error = [NSError errorWithDomain:kErrorDomain code:errorCode userInfo:userInfo];
    
    [delegate uploadFailed:filePath error:error];
}

@end
