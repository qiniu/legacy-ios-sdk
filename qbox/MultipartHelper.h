//
//  MultipartHelper.h
//  QBox
//
//  Created by bert yuan on 11/1/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface MultipartHelper : NSObject

@property(retain, readonly)    NSMutableURLRequest     *request;

- (id)initWithRequest:(NSMutableURLRequest *)req;


//Call this method to add first 1, ..., n-1 part sequently
//If there is only one part, call next method
- (void)addMultipartToBody:(NSData *)data 
                      name:(NSString *)name 
                  fileName:(NSString *)fileName 
               contentType:(NSString *)contentType;

//Call this method to add the last part
//If there is only one part, call this method directly
- (void)addLastMultipartToBody:(NSData *)data 
                          name:(NSString *)name 
                      fileName:(NSString *)fileName 
                   contentType:(NSString *)contentType;

@end
