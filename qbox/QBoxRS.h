//
//  QBoxRS.h
//  QBox
//
//  Created by bert yuan on 11/1/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface QBoxRS : NSObject

+ (int)putFileWithUrl:(NSString *)url 
            tableName:(NSString *)tableName
                  key:(NSString *)key
             mimeType:(NSString *)mimeType
             filePath:(NSString *)file
           customMeta:(NSString *)customMeta
       callbackParams:(id)callbackParams;



@end
