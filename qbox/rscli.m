//
//  QBoxRS.m
//  QBox
//
//  Created by bert yuan on 11/1/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "rscli.h"
#import "MultipartHelper.h"

@implementation RSClient

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

+ (QBox_Error)resumablePutFile:(NSString *)upToken    
                     tableName:(NSString *)tableName
                           key:(NSString *)key
                      mimeType:(NSString *)mimeType
                          file:(NSString *)file
                      progress:(QBox_UP_Progress *)progress
                   blockNotify:(QBox_UP_FnBlockNotify) blockNotify
                   chunkNotify:(QBox_UP_FnChunkNotify) chunkNotify
                  notifyParams:(void*) notifyParams
                        putRet:(QBox_UP_PutRet*)putRet
                    customMeta:(NSString *)customMeta
                callbackParams:(NSString *)callbackParams
{
    
    QBox_Error err;
    QBox_Client client;
    QBox_AuthPolicy auth;
    QBox_ReaderAt f;
    char* entry = NULL;
    QBox_Int64 fsize = 0;

    NSLog(@"\nSending request...\ntable name:%@\nkey:%@\nmimeType:%@\nfile:%@\ncustomMeta:%@\ncallbackParams:%@\n", 
          tableName,key, mimeType, file, customMeta, callbackParams);
    
    /* Upload file */
    QBox_Zero(client);
    QBox_Zero(auth);
    
    QBox_Client_InitByUpToken(&client, [upToken cStringUsingEncoding:NSASCIIStringEncoding], 1024);
    
    f = QBox_FileReaderAt_Open([file cStringUsingEncoding:NSASCIIStringEncoding]);
    
    if ((int)f.self >= 0) {
        fsize = (QBox_Int64) lseek((int)f.self, 0, SEEK_END);
        
        entry = QBox_String_Concat([tableName cStringUsingEncoding:NSASCIIStringEncoding], ":", [key cStringUsingEncoding:NSASCIIStringEncoding], NULL);
        err = QBox_RS_ResumablePut(
                                   &client,
                                   putRet,
                                   progress,
                                   blockNotify, /* blockNotify    */
                                   chunkNotify, /* chunkNotify    */
                                   notifyParams, /* notifyParams   */
                                   entry,
                                   [mimeType cStringUsingEncoding:NSASCIIStringEncoding],
                                   f,
                                   fsize,
                                   [customMeta cStringUsingEncoding:NSASCIIStringEncoding], /* customMeta     */
                                   [callbackParams cStringUsingEncoding:NSASCIIStringEncoding]  /* callbackParams */
                                   );
        free(entry);
        
        QBox_FileReaderAt_Close(f.self);
        
        if (err.code != 200) {
            NSLog(@"QBox_RS_ResumablePut failed: %d - %s", err.code, err.message);
            return err;
        }
    }
    
    QBox_Client_Cleanup(&client);
    
    return err;
}

@end
