//
//  MultipartHelper.m
//  QBox
//
//  Created by bert yuan on 11/1/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "MultipartHelper.h"
#import "stdlib.h"
#import "NSObject+Encodings.h"
#import <CommonCrypto/CommonDigest.h>


@interface MultipartHelper ()


@property(retain, readwrite)    NSMutableURLRequest     *request;
@property(retain, readonly)     NSMutableData           *bodyData;
@property(retain, readonly)     NSString                *boundary;

@end



@implementation MultipartHelper

@synthesize request         = _request;
@synthesize bodyData        = _bodyData;
@synthesize boundary        = _boundary;

- (id)initWithRequest:(NSMutableURLRequest *)req {
    
    self = [super init];
    if (self) {
        self.request = req;
    }
    return self;
}

- (void)dealloc {
    
    [_request release];
    [_bodyData release];
    [_boundary release];
    [super dealloc];
}

- (NSMutableData *)bodyData {
    
    if (_bodyData == nil) {
        _bodyData = [[NSMutableData data] retain];
    }
    return _bodyData;
}

- (NSString *)boundary {
    
    if (_boundary == nil) {
        //use random time to generate a random string as boundary
        NSDate *date = [[NSDate date] dateByAddingTimeInterval:(random()%10000)];
        NSDateComponents *components = [[NSCalendar currentCalendar] components: NSSecondCalendarUnit | NSMinuteCalendarUnit | NSHourCalendarUnit | NSDayCalendarUnit | NSMonthCalendarUnit | NSYearCalendarUnit fromDate:date];
        
        NSString *timestamp = [NSString stringWithFormat:@"%04d%02d%02d%02d%02d%02d%ld", [components year], [components month], [components day], [components hour], [components minute], [components second], (long)random()];
        _boundary = [timestamp retain];
    }
    return _boundary;
}

- (void)addMultipartToBody:(NSData *)data 
                      name:(NSString *)name 
                  fileName:(NSString *)fileName 
               contentType:(NSString *)contentType
{
    
    //header of this part
    NSMutableString *header = [NSMutableString string];
    [header appendFormat:@"--%@\r\n", self.boundary];
    [header appendFormat:@"Content-Disposition: form-data; name=\"%@\"", name];
    if (fileName != nil) {
        [header appendFormat:@"; filename=\"%@\"\r\n", fileName];
    } else {
        [header appendString:@"\r\n"];
    }
    if (contentType != nil) {
        [header appendFormat:@"Content-Length: %d\r\n", (int) [data length]];
        [header appendFormat:@"Content-Type: %@\r\n", contentType];
        [header appendFormat:@"Content-Transfer-Encoding: binary\r\n"];        
    }
    [header appendString:@"\r\n"];
    
    
    //add header of this part to body
    [self.bodyData appendData:[header dataUsingEncoding:NSASCIIStringEncoding]];
    
    //add body of this part
    [self.bodyData appendData:data];
    
    //footer for this part
    NSString *partFooter = @"\r\n";
    [self.bodyData appendData:[partFooter dataUsingEncoding:NSASCIIStringEncoding]];
}

- (void)addLastMultipartToBody:(NSData *)data 
                          name:(NSString *)name 
                      fileName:(NSString *)fileName 
                   contentType:(NSString *)contentType {
    
    //add last part first
    [self addMultipartToBody:data name:name fileName:fileName contentType:contentType];
    
    //set footer
    NSMutableString *footer = [NSMutableString string];
    [footer appendString:@"\r\n"];
    [footer appendFormat:@"--%@--\r\n\r\n", self.boundary];
    [self.bodyData appendData:[footer dataUsingEncoding:NSASCIIStringEncoding]];
    
    [self.request setHTTPBody:self.bodyData];
    
    //set http Content-Type
    NSString *httpContentType = [NSString stringWithFormat:@"multipart/form-data; boundary=%@", self.boundary];
    [self.request setValue:httpContentType forHTTPHeaderField:@"Content-Type"];
    
    //set Content-Length
    [self.request setValue:[NSString stringWithFormat:@"%d", (int)self.bodyData.length] forHTTPHeaderField:@"Content-Length"];
    
    //set http method to @"POST"
    [self.request setHTTPMethod:@"POST"];
}

@end
