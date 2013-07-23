//
//  QiniuBlockUpload.h
//  QiniuBlockUpload
//
//  Created by Qiniu Developers 2013
//

#import <Foundation/Foundation.h>
#import "QiniuBlockUploadDelegate.h"
#import "QiniuBlkputRet.h"
#import "QiniuRioPutExtra.h"

@interface QiniuBlockUploader : NSOperation
{
    int _blockIndex;
    long long _blockSize;
    NSData *_blockData;
    NSString *_token;
    QiniuBlkputRet *_progress;
    QiniuRioPutExtra *_params;
}

@property (retain) id<QiniuBlockUploadDelegate> delegate;

- (id)initWithToken:(NSString *)token
         blockIndex:(int)blockIndex
          blockData:(NSData *)blockData
           progress:(QiniuBlkputRet *)progress
             params:(QiniuRioPutExtra *)params;

@end
