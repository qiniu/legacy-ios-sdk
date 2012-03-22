//
//  NSDictionary+Utils.m
//  Demo
//
//  Created by bert yuan on 11/4/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "NSDictionary+Utils.h"
#import "NSObject+Encodings.h"

@implementation NSDictionary (Utils)

- (NSString *)httpFormString {
    NSMutableArray* arguments = [NSMutableArray arrayWithCapacity:[self count]];

    NSString* key = nil;
    NSEnumerator *enumerator = [self keyEnumerator];
    while (key = [enumerator nextObject]) {
        [arguments addObject:[NSString stringWithFormat:@"%@=%@",
                              [[key dataUsingEncoding:NSASCIIStringEncoding] urlsafeBase64Encode],
                              [[[self objectForKey:key] dataUsingEncoding:NSASCIIStringEncoding] urlsafeBase64Encode]]];
    }
    
    return [arguments componentsJoinedByString:@"&"];
}

@end
