//
//  NSObject+Encodings.m
//  QBox
//
//  Created by bert yuan on 6/18/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "NSObject+Encodings.h"
#import "UrlsafeBase64Transcoder.h"
//#import "urlsafe_b64.h"


@implementation NSData (NSData_urlsafeBase64Encode)

- (NSString *)urlsafeBase64Encode {
	size_t count = EstimateBas64EncodedDataSize([self length]);
	char *buf = malloc(count + 1);
	NSString *result = nil;
	if (UrlsafeBase64EncodeData([self bytes], [self length], buf, &count) && count) {
		buf[count] = '\0';
		result = [[[NSString alloc] initWithBytes:buf length:count encoding:NSASCIIStringEncoding] autorelease];
	}
	free(buf);
	return result;
}
/*
- (NSString *)urlsafeBase64Encode {
	size_t count = urlsafe_b64_encode([self bytes], [self length], NULL, 0);
	char *buf = malloc(count + 1);
	NSString *result = nil;
	if (count = urlsafe_b64_encode([self bytes], [self length], buf, count) && count) {
		buf[count] = '\0';
		result = [[[NSString alloc] initWithBytes:buf length:count encoding:NSASCIIStringEncoding] autorelease];
	}
	free(buf);
	return result;
}
*/
@end



@implementation NSString (NSString_urlsafeBase64Decode)

- (NSData *)urlsafeBase64Decode {
	NSData *srcData = [self dataUsingEncoding:NSASCIIStringEncoding];
	size_t count = EstimateBas64DecodedDataSize([srcData length]);
	char *buf = malloc(count + 1);
	NSData *result = nil;
	if (UrlsafeBase64DecodeData([srcData bytes], [srcData length], buf, &count) && count) {
		buf[count] = '\0';
		result = [NSData dataWithBytes:buf length:count];
	}
	free(buf);
	return result;
}

/*
- (NSData *)urlsafeBase64Decode {
	NSData *srcData = [self dataUsingEncoding:NSASCIIStringEncoding];
	size_t count = urlsafe_b64_decode([srcData bytes], [srcData length], NULL, 0);
	char *buf = malloc(count + 1);
	NSData *result = nil;
	if (count = urlsafe_b64_decode([srcData bytes], [srcData length], buf, count) && count) {
		buf[count] = '\0';
		result = [NSData dataWithBytes:buf length:count];
	}
	free(buf);
	return result;
}
*/
@end

