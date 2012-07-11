//
//  QBoxRS.h
//  QBox
//
//  Created by bert yuan on 11/1/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

#include "rs.h"

@interface RSClient : NSObject

+ (int)putFileWithUrl:(NSString *)url 
            tableName:(NSString *)tableName
                  key:(NSString *)key
             mimeType:(NSString *)mimeType
             filePath:(NSString *)file
           customMeta:(NSString *)customMeta
       callbackParams:(id)callbackParams;

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
                callbackParams:(NSString *)callbackParams;

@end
