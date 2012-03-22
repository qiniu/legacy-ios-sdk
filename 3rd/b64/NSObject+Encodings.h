//
//  NSObject+Encodings.h
//  QBox
//
//  Created by bert yuan on 6/18/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface NSData (NSData_urlsafeBase64Encode)

- (NSString *)urlsafeBase64Encode;

@end



@interface NSString (NSString_urlsafeBase64Decode)

- (NSData *)urlsafeBase64Decode;

@end