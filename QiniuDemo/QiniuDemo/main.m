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

int main(int argc, char *argv[])
{
    @autoreleasepool {
        //return UIApplicationMain(argc, argv, nil, NSStringFromClass([QiniuAppDelegate class]));
        QiniuResumableUploadDemo *instance = [[QiniuResumableUploadDemo alloc] initWithFile:@"/Users/shijy/vtest.mov" persistenceDir:@"/Users/shijy/iostest"];
        [instance resumalbleUpload:@"test-r3.mov"];
        int waitLoop = 0;
        while (waitLoop < 1000)
        {
            NSLog(@"Waiting for the result...");
            [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:1.0]];
            waitLoop++;
        }
    }
}
