//
//  main.m
//  QiniuDemo
//
//  Created by Qiniu Developers on 12-11-14.
//  Copyright (c) 2012 Shanghai Qiniu Information Technologies Co., Ltd. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "QiniuAppDelegate.h"
#import "QiniuResumableUploadDemo.h"
#import "QiniuPutPolicy.h"

static NSString *QiniuAccessKey = @"<Please specify your access key>";
static NSString *QiniuSecretKey = @"<Please specify your secret key>";
static NSString *QiniuBucketName = @"<Please specify your bucket name>";

int main(int argc, char *argv[])
{
    @autoreleasepool {
        //return UIApplicationMain(argc, argv, nil, NSStringFromClass([QiniuAppDelegate class]));
        
        // token
        QiniuAccessKey = @"dbsrtUEWFt_HMlY59qw5KqaydbvML1zxtxsvioUX";
        QiniuSecretKey = @"EZUwWLGLfbq0y94SLteofzzqKc60Dxg5kc1Rv2ct";
        QiniuBucketName = @"shijy";
        QiniuPutPolicy *policy = [[QiniuPutPolicy new] autorelease];
        policy.expires = 36000;
        policy.scope = QiniuBucketName;
        NSString *token = [policy makeToken:QiniuAccessKey secretKey:QiniuSecretKey];
        
        // test case
        NSString *key = @"test-qq8.mov";
        NSString *filePath = @"/Users/qiniu/vtest.mov";
        NSString *persistenceDir = @"/Users/qiniu/iostest";
        
        // resumable upload
        QiniuResumableUploadDemo *instance = [[QiniuResumableUploadDemo alloc] initWithToken:token];
        [instance resumalbleUploadFile:filePath persistenceDir:persistenceDir bucket:QiniuBucketName key:key];
        
        // test pause and resume
        for (int i = 0; i < 3; i++) {
            [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:10.0]];
            NSLog(@"Stop Upload ...");
            [instance stopUpload];
            [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:1.0]];
            NSLog(@"Resumalble Upload ...");
            [instance resumalbleUploadFile:filePath persistenceDir:persistenceDir bucket:QiniuBucketName key:key];
        }
        int waitLoop = 0;
        while (waitLoop < 1000)
        {
            NSLog(@"Waiting for the result...");
            [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:1.0]];
            waitLoop++;
        }
    }
}
