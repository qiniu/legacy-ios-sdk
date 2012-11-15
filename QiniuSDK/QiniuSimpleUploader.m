//
//  QiniuSimpleUploader.m
//  QiniuSimpleUploader
//
//  Created by Hugh Lv on 12-11-14.
//  Copyright (c) 2012 Shanghai Qiniu Information Technologies Co., Ltd. All rights reserved.
//

#import "QiniuConfig.h"
#import "QiniuSimpleUploader.h"
#import "ASIFormDataRequest.h"
#import "GTMBase64.h"
#import "SBJson.h"

@implementation QiniuSimpleUploader

@synthesize token;
@synthesize delegate;

- (id) init
{
    self = [super init];
    
    self->sentBytes = 0;
    
    return self;
}

- (void) upload:(NSString *)filePath bucket:(NSString *)bucket key:(NSString *)key extraParams:(NSDictionary *)extraParams
{
    NSString *url = [NSString stringWithFormat:@"%@/upload", kUpHost];
    ASIFormDataRequest *request = [[ASIFormDataRequest alloc] initWithURL:[NSURL URLWithString:url]];
    request.delegate = self;
    request.uploadProgressDelegate = self;
    
    NSString *mimeType = @"application/octet-stream";
    NSObject *mimeTypeObj = [extraParams objectForKey:@"mimeType"];
    if (mimeTypeObj != nil) {
        mimeType = (NSString *)mimeTypeObj;
    }
    NSString *encodedMimeType = [GTMBase64 stringByWebSafeEncodingData:[mimeType dataUsingEncoding:NSUTF8StringEncoding] padded:TRUE];
    
    NSString *encodedEntry = [GTMBase64 stringByWebSafeEncodingData:[[NSString stringWithFormat:@"%@:%@", bucket, key] dataUsingEncoding:NSUTF8StringEncoding] padded:TRUE];
    
    NSMutableString *action = [NSMutableString stringWithFormat:@"/rs-put/%@/mimeType/%@", encodedEntry, encodedMimeType];
    
    NSObject *customMetaObj = [extraParams objectForKey:@"customMeta"];
    if (customMetaObj != nil) {
        NSString *customMeta = (NSString *)customMetaObj;
        NSString *encodedCustomMeta = [GTMBase64 stringByWebSafeEncodingData:[customMeta dataUsingEncoding:NSUTF8StringEncoding] padded:TRUE];
        
        [action appendFormat:@"/meta/%@", encodedCustomMeta];
    }
    
    [request addPostValue:action forKey:@"action"];
    [request addFile:filePath forKey:@"file"];
    
    if (self.token != nil) {
        [request addPostValue:token forKey:@"auth"];
    }
    
    NSObject *callbackParamsObj = [extraParams objectForKey:@"callbackParams"];
    if (callbackParamsObj != nil) {
        NSDictionary *callbackParams = (NSDictionary *)callbackParamsObj;
        
        // Convert NSDictionary to strings like: key1=value1&key2=value2&key3=value3 ...
        
        NSMutableString *callbackParamsStr = [NSMutableString string];
        for (NSString *key in [callbackParams allKeys]) {
            if ([callbackParamsStr length] > 0) {
                [callbackParamsStr appendString:@"&"];
            }
            [callbackParamsStr appendFormat:@"%@=%@", key, [callbackParams objectForKey:key]];
        }
        [request addPostValue:callbackParamsStr forKey:@"params"];
    }
    
    NSNumber* fileSizeNumber = [[[NSFileManager defaultManager] attributesOfItemAtPath:filePath error:nil] objectForKey:NSFileSize];
    
    NSDictionary *context = [NSDictionary dictionaryWithObjectsAndKeys:filePath, @"filePath",
                             fileSizeNumber, @"fileSize",
                             bucket, @"bucket",
                             key, @"key",
                             extraParams, @"extraParams",
                             nil];
    
    [request setUserInfo:context];
    
    [request startAsynchronous];
}

// Progress
- (void) request:(ASIHTTPRequest *)request didSendBytes:(long long)bytes
{
    sentBytes += bytes;
    NSString *filePath = (NSString *)[[request userInfo] objectForKey:@"filePath"];
    long long fileSize = [(NSNumber *)([[request userInfo] objectForKey:@"fileSize"]) longLongValue];
    if (fileSize > 0) {
        float percent = (float)((double)sentBytes / fileSize);
        [delegate uploadProgressUpdated:filePath percent:percent];
    }
}

// Finished. This does not indicate a OK result.
- (void) requestFinished:(ASIHTTPRequest *)request
{
    NSString *filePath = (NSString *)[[request userInfo] objectForKey:@"filePath"];

    int statusCode = [request responseStatusCode];
    SBJsonParser *parser = [[SBJsonParser alloc] init];
    NSDictionary *dic = [parser objectWithString:[request responseString]];
    
    if (statusCode / 100 == 2) { // Success!
        
        NSString *hash = nil;
        NSObject *hashObj = [dic objectForKey:@"hash"];
        if (hashObj != nil) {
            hash = (NSString *)hashObj;
        }
        
        [delegate uploadProgressUpdated:filePath percent:1.0]; // Ensure a 100% progress message is sent.
        [delegate uploadSucceeded:filePath hash:hash];
    } else {
        
        NSLog(@"Post failed: %d %@ - %@", statusCode, [request responseStatusMessage], [request responseString]);
        
        NSString *error = nil;
        NSObject *errorObj = [dic objectForKey:@"error"];
        if (errorObj != nil) {
            error = (NSString *)errorObj;
        }
        
        [delegate uploadFailed:filePath error:[NSError errorWithDomain:@"QiniuSimpleUploader" code:statusCode userInfo:[NSDictionary dictionaryWithObject:error forKey:@"error"]]];
    }
    [parser release];
}

// Failed.
- (void) requestFailed:(ASIHTTPRequest *)request
{
    NSString *filePath = (NSString *)[[request userInfo] objectForKey:@"filePath"];
    [delegate uploadFailed:filePath error:[NSError errorWithDomain:@"QiniuSimpleUploader" code:[[request error] code] userInfo:[NSDictionary dictionaryWithObject:[[request error] localizedDescription] forKey:@"error"]]];
}

@end
