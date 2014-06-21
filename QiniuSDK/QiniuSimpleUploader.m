//
//  QiniuSimpleUploader.m
//  QiniuSimpleUploader
//
//  Created by Qiniu Developers 2013
//

#import "QiniuConfig.h"
#import "QiniuSimpleUploader.h"
#import "QiniuUtils.h"

@interface QiniuSimpleUploader ()
//@property(nonatomic,copy)NSString *filePath;
//@property(nonatomic,assign)uint64_t *fileSize;
//@property(nonatomic,assign)uint64_t *sentBytes;
@end

// ------------------------------------------------------------------------------------------

@implementation QiniuSimpleUploader

+ (id) uploaderWithToken:(NSString *)token {
    return [[self alloc] initWithToken:token];
}

// Must always override super's designated initializer.
- (id)init {
    return [self initWithToken:nil];
}

- (id)initWithToken:(NSString *)token {
    if (self = [super init]) {
        self.token = token;
    }
    return self;
}

- (void) uploadFile:(NSString *)filePath
                key:(NSString *)key
              extra:(QiniuPutExtra *)extra
{
   
    NSParameterAssert(filePath);
    NSParameterAssert(self.token);
    
    if (extra == nil) {
        extra = [[QiniuPutExtra alloc] init];
    }
    if (extra.mimeType == nil) {
        extra.mimeType = @"";
    }
    
    NSURL *url = [NSURL URLWithString:kQiniuUpHost];
    AFHTTPClient *httpClient = [AFHTTPClient clientWithBaseURL:url];


    NSMutableURLRequest *request = [httpClient multipartFormRequestWithMethod:@"POST" path:@"/" parameters:nil constructingBodyWithBlock:^(id<AFMultipartFormData> formData) {
        
        NSData *data = [NSData dataWithContentsOfFile:filePath];
        [formData appendPartWithFileData:data name:@"file" fileName:filePath mimeType:extra.mimeType];
        
        [formData appendPartWithFormData:[self.token dataUsingEncoding:NSUTF8StringEncoding] name:@"token"];
        if (key) {
            [formData appendPartWithFormData:[key dataUsingEncoding:NSUTF8StringEncoding] name:@"key"];
        }
        
        for (NSString* xkey in extra.params) {
            [formData appendPartWithFormData:[[extra.params objectForKey:xkey] dataUsingEncoding:NSUTF8StringEncoding] name:xkey];
        }
    }];
    
    [request setValue:kQiniuUserAgent forHTTPHeaderField:@"User-Agent"];
    
    // init operation with request, success, failure
    AFJSONRequestOperation *operation = [AFJSONRequestOperation JSONRequestOperationWithRequest:request success:^(NSURLRequest *request, NSHTTPURLResponse *response, id JSON) {
        if ([response statusCode] != 200) {
            NSError *error = qiniuErrorWithResponse(response, JSON, nil);
            [self.delegate uploadFailed:filePath error:error];
            return;
        }
        [self.delegate uploadSucceeded:filePath ret:JSON];
    } failure:^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error, id JSON) {
        error = qiniuErrorWithResponse(response, JSON, error);
        [self.delegate uploadFailed:filePath error:error];
    }];

    // set upload progress delegate
    if ([self.delegate respondsToSelector:@selector(uploadProgressUpdated:percent:)]) {
        
        [operation setUploadProgressBlock:^(NSUInteger bytesWritten, long long totalBytesWritten, long long totalBytesExpectedToWrite) {
            
            float percent = (float)totalBytesWritten / (float)totalBytesExpectedToWrite;
            [self.delegate uploadProgressUpdated:filePath percent:percent];
        }];
    }

    [operation start];
}

@end

@implementation QiniuPutExtra

+ (QiniuPutExtra *) extraWithParams:(NSDictionary *)params
                           mimeType:(NSString *)mimeType{
    QiniuPutExtra *extra = [[QiniuPutExtra alloc] init];
    extra.params = params;
    extra.mimeType = mimeType;
    return extra;
}

@end


