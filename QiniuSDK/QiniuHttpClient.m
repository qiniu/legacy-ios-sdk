
//
//  QiniuClient.m
//  QiniuSDK
//
//  Created by 张光宇 on 2/9/14.
//  Copyright (c) 2014 Shanghai Qiniu Information Technologies Co., Ltd. All rights reserved.
//

#import "QiniuHttpClient.h"
#import "QiniuConfig.h"
#import "QiniuUtils.h"

@implementation QiniuHttpClient

+ (instancetype)sharedInstance{
    static QiniuHttpClient *_sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _sharedInstance = [[self alloc] init];
        //        assert(_DefaultSpaceName);
        //        _sharedInstance.spaceName = _DefaultSpaceName;
    });
    return _sharedInstance;
}

- (AFHTTPRequestOperation *)uploadFile:(NSString *)filePath
                                   key:(NSString *)key
                                 token:(NSString *)token
                                 extra:(QiniuPutExtra *)extra
                                uphost:(NSString *)uphost
                              progress:(void (^)(float percent))progressBlock
                              complete:(QNObjectResultBlock)complete{
    
    NSParameterAssert(filePath);
    NSParameterAssert(token);
    NSError *error = nil;
    [[[NSFileManager defaultManager] attributesOfItemAtPath:filePath error:&error] fileSize];
    
    if (error) {
        complete(nil,error);
        return nil;
    }
    
    NSData *data = [NSData dataWithContentsOfFile:filePath];
    return [self uploadFileData:data
                            key:key
                          token:token
                          extra:extra
                         uphost:uphost
                       progress:progressBlock
                       complete:complete];
}

- (AFHTTPRequestOperation *)uploadFileData:(NSData *)data
                                       key:(NSString *)key
                                     token:(NSString *)token
                                     extra:(QiniuPutExtra *)extra
                                    uphost:(NSString *)uphost
                                  progress:(void (^)(float percent))progressBlock
                                  complete:(QNObjectResultBlock)complete{

    NSParameterAssert(data);
    NSParameterAssert(token);
    
    NSMutableDictionary *parameters = [NSMutableDictionary dictionary];

    if (key && ![key isEqualToString:kQiniuUndefinedKey]) {
        parameters[@"key"] = key;
    }
    if (!key) {
        key = kQiniuUndefinedKey;
    }

    parameters[@"token"] = token;
    
    if (extra) {
        [parameters addEntriesFromDictionary:extra.convertToPostParams];
    }

    NSString *mimeType = extra.mimeType;
    if (!mimeType) {
        mimeType = @"application/octet-stream";
    }

    NSMutableURLRequest *request = [self.requestSerializer multipartFormRequestWithMethod:@"POST"
                                                                                URLString:uphost
                                                                               parameters:parameters
                                                                constructingBodyWithBlock:^(id<AFMultipartFormData> formData) {
                                                                    
                                                                    [formData appendPartWithFileData:data
                                                                                                name:@"file"
                                                                                            fileName:key
                                                                                            mimeType:mimeType];
                                                                } error:nil];


    AFHTTPRequestOperation *operation = [self HTTPRequestOperationWithRequest:request
                                                                      success:^(AFHTTPRequestOperation *operation, id responseObject) {
        complete(operation,nil);
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        complete(operation,error);
    }];

    [operation setUploadProgressBlock:^(NSUInteger bytesWritten, long long totalBytesWritten, long long totalBytesExpectedToWrite) {
        progressBlock((float)totalBytesWritten / (float)totalBytesExpectedToWrite);
    }];
    [self.operationQueue addOperation:operation];
    return operation;
}


- (AFHTTPRequestOperation *)HTTPRequestOperationWithRequest:(NSURLRequest *)theRequest
                                                    success:(void (^)(AFHTTPRequestOperation *, id))success
                                                    failure:(void (^)(AFHTTPRequestOperation *, NSError *))failure{

    NSMutableURLRequest *request = (NSMutableURLRequest *)theRequest;
    [request addValue:qiniuUserAgent() forHTTPHeaderField:@"User-Agent"];
    AFHTTPRequestOperation *operation = [super HTTPRequestOperationWithRequest:request success:success failure:failure];

    return operation;
}

@end


@implementation QiniuPutExtra

- (NSDictionary *)convertToPostParams{
    NSMutableDictionary *params = [NSMutableDictionary dictionaryWithDictionary:self.params];
    if (self.checkCrc == 1) {
        params[@"crc32"] = [NSString stringWithFormat:@"%ld", self.crc32];
    }
    return params;
}

@end
