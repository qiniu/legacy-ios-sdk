//
//  QiniuSimpleUploader.h
//  QiniuSimpleUploader
//
//  Created by Hugh Lv on 12-11-14.
//  Copyright (c) 2012 Shanghai Qiniu Information Technologies Co., Ltd. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "QiniuUploadDelegate.h"
#import "ASIHTTPRequest/ASIFormDataRequest.h"

@interface QiniuSimpleUploader : NSObject<ASIHTTPRequestDelegate, ASIProgressDelegate> {
    NSString *token;
    id<QiniuUploadDelegate> delegate;
    long long sentBytes;
}

@property (retain, nonatomic) NSString *token;

// Delegates.
@property (retain, nonatomic) id<QiniuUploadDelegate> delegate;

- (void) upload:(NSString *)filePath bucket:(NSString *)bucket key:(NSString *)key extraParams:(NSDictionary *)extraParams;

@end
