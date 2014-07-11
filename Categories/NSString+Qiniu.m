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
	return [[NSString stringWithFormat:@"%@?imageInfo", self] stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
}

- (NSString *)qnEXIF
{
	return [[NSString stringWithFormat:@"%@?exif", self] stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
}

- (NSString *)qnScaleToPercent:(CGFloat)percent
{
	return [[NSString stringWithFormat:@"%@?imageMogr/v2/thumbnail/!%fp", self, percent] stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
}

- (NSString *)qnScaleFitWidth:(CGFloat)width
{
	return [[NSString stringWithFormat:@"%@?imageMogr/v2/thumbnail/%f", self, width] stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
}

- (NSString *)qnScaleFitHeight:(CGFloat)height
{
	return [[NSString stringWithFormat:@"%@?imageMogr/v2/thumbnail/x%f", self, height] stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
}

- (NSString *)qnScaleAspectFit:(CGSize)size
{
	return [[NSString stringWithFormat:@"%@?imageMogr/v2/thumbnail/%fx%f", self, size.width, size.height] stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
}

- (NSString *)qnScaleAspectFill:(CGSize)size
{
	return [[NSString stringWithFormat:@"%@?imageMogr/v2/thumbnail/%fx%f^", self, size.width, size.height] stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
}

- (NSString *)qnScaleToFill:(CGSize)size
{
	return [[NSString stringWithFormat:@"%@?imageMogr/v2/thumbnail/%fx%f!", self, size.width, size.height] stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
}

- (NSString *)qnCropFromCenterToSize:(CGSize)size
{
	return [[NSString stringWithFormat:@"%@?imageMogr/v2/gravity/center/crop/!%fx%f", self, size.width, size.height] stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
}

@end
