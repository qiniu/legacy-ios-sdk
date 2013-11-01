//
//  NSString+Qiniu.m
//  find
//
//  Created by qq30135878 on 11/1/13.
//  Copyright (c) 2013 zhangbin. All rights reserved.
//

#import "NSString+Qiniu.h"

@implementation NSString (Qiniu)

- (NSString *)qnImageInfo
{
	return [NSString stringWithFormat:@"%@?imageInfo", self];
}

- (NSString *)qnEXIF
{
	return [NSString stringWithFormat:@"%@?exif", self];
}

- (NSString *)qnScaleToPercent:(CGFloat)percent
{
	return [NSString stringWithFormat:@"%@?imageMogr/v2/thumbnail/!%fp", self, percent];
}

- (NSString *)qnScaleFitWidth:(CGFloat)width
{
	return [NSString stringWithFormat:@"%@?imageMogr/v2/thumbnail/%f", self, width];
}

- (NSString *)qnScaleFitHeight:(CGFloat)height
{
	return [NSString stringWithFormat:@"%@?imageMogr/v2/thumbnail/x%f", self, height];
}

- (NSString *)qnScaleAspectFit:(CGSize)size
{
	return [NSString stringWithFormat:@"%@?imageMogr/v2/thumbnail/%fx%f", self, size.width, size.height];
}

- (NSString *)qnScaleAspectFill:(CGSize)size
{
	return [NSString stringWithFormat:@"%@?imageMogr/v2/thumbnail/%fx%f^", self, size.width, size.height];
}

- (NSString *)qnScaleToFill:(CGSize)size
{
	return [NSString stringWithFormat:@"%@?imageMogr/v2/thumbnail/%fx%f!", self, size.width, size.height];
}

- (NSString *)qnCropFromCenterToSize:(CGSize)size
{
	return [NSString stringWithFormat:@"%@?imageMogr/v2/gravity/center/crop/!%fx%f", self, size.width, size.height];
}

@end
