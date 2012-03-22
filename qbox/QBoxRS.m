//
//  QBoxRS.m
//  QBox
//
//  Created by bert yuan on 11/1/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "QBoxRS.h"
#import "NSObject+Encodings.h"
#import "MultipartHelper.h"
#import "NSDictionary+Utils.h"


@implementation QBoxRS

+(int)putFileWithUrl:(NSString *)url 
           tableName:(NSString *)tableName
                 key:(NSString *)key
            mimeType:(NSString *)mimeType
            filePath:(NSString *)file
          customMeta:(NSString *)customMeta
      callbackParams:(id)callbackParams
{
    NSLog(@"\nSending request...\nurl:%@\ntable name:%@\nkey:%@\nmimeType:%@\nfile:%@\ncustomMeta:%@\ncallbackParams:%@\n", 
          url, tableName,key, mimeType, file, customMeta, callbackParams);

    if (mimeType == nil) {
        mimeType = @"application/octet-stream";
    }
    NSString *entryUri = [NSString stringWithFormat:@"%@:%@", tableName, key];
    
    
    NSString *action = [NSString stringWithFormat:@"/rs-put/%@/mimeType/%@", 
                        [[entryUri dataUsingEncoding:NSASCIIStringEncoding] urlsafeBase64Encode],
                        [[mimeType dataUsingEncoding:NSASCIIStringEncoding] urlsafeBase64Encode]];
    if (customMeta != nil) {
        action = [action stringByAppendingFormat:@"/meta/%@", 
                  [[customMeta dataUsingEncoding:NSASCIIStringEncoding] urlsafeBase64Encode]];
    }


    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:[NSURL URLWithString:url]];

    MultipartHelper *multipart = [[MultipartHelper alloc] initWithRequest:request];
    [multipart addMultipartToBody:[action dataUsingEncoding:NSASCIIStringEncoding]
                             name:@"action" 
                         fileName:nil 
                      contentType:nil];

    if (callbackParams != nil) {
        if ([callbackParams isKindOfClass:[NSDictionary class]]) {
            callbackParams = [callbackParams httpFormString];
        }
        [multipart addMultipartToBody:[callbackParams dataUsingEncoding:NSASCIIStringEncoding]
                                 name:@"params" 
                             fileName:nil 
                          contentType:nil];
    }
    
    [multipart addLastMultipartToBody:[NSData dataWithContentsOfFile:file]
                                 name:@"file" 
                             fileName:file 
                          contentType:@"application/octet-stream"];
    [multipart release];
    

    NSHTTPURLResponse *response = nil;
    NSError *error = nil;
    NSData *resultData = [NSURLConnection sendSynchronousRequest:request returningResponse:&response error:&error];
    [request release];

    NSString *resultStr = [NSString stringWithCString:resultData.bytes encoding:NSASCIIStringEncoding];
    NSLog(@"\nReceived result...\nresponse:%@\nerror:%@\nresult:%@\nstatusCode=%d\n", 
          response, error, resultStr, [response statusCode]);

    return [response statusCode];
}

@end
