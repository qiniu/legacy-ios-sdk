//
//  NSString+Qiniu.h
//  find
//
//  Created by qq30135878 on 11/1/13.
//  Copyright (c) 2013 zhangbin. All rights reserved.
//

#import <Foundation/Foundation.h>

//注意Qiniu的width，height，size是用的px，不是pt，Retina屏幕需要乘2，假设需要请求填满当前view的一张图片，需要CGSizeMake(self.view.bounds.size.width * 2, self.view.bounds.size.height * 2)

@interface NSString (Qiniu)

- (NSString *)qnImageInfo;
- (NSString *)qnEXIF;

//基于原图大小，按照指定的百分比进行缩放。
//http://qiniuphotos.qiniudn.com/gogopher.jpg?imageMogr/v2/thumbnail/!50p
- (NSString *)qnScaleToPercent:(CGFloat)percent;

//限定缩略图宽度，高度等比自适应。
//http://qiniuphotos.qiniudn.com/gogopher.jpg?imageMogr/v2/thumbnail/200
- (NSString *)qnScaleFitWidth:(CGFloat)width;

//限定缩略图高度，宽度等比自适应。
//http://qiniuphotos.qiniudn.com/gogopher.jpg?imageMogr/v2/thumbnail/x100
- (NSString *)qnScaleFitHeight:(CGFloat)height;

//限定长边，短边自适应，将缩略图的大小限定在指定的宽高矩形内。若指定的宽度大于指定的高度，以指定的高度为基准，宽度自适应等比缩放；若指定的宽度小于指定的高度，以指定的宽度为基准，高度自适应等比缩放。
//http://qiniuphotos.qiniudn.com/gogopher.jpg?imageMogr/v2/thumbnail/100x200
- (NSString *)qnScaleAspectFit:(CGSize)size;


//限定短边，长边自适应，目标缩略图大小会超出指定的宽高矩形。若指定的宽度大于指定的高度，以指定的宽度为基准，高度自适应等比缩放；若指定的宽度小于指定的高度，以指定的高度为基准，宽度自适应等比缩放。
//http://qiniuphotos.qiniudn.com/gogopher.jpg?imageMogr/v2/thumbnail/100x200^
- (NSString *)qnScaleAspectFill:(CGSize)size;


//限定缩略图宽和高。缩略图按照指定的宽和高强行缩略，忽略原图宽和高的比例，可能会变形。
//http://qiniuphotos.qiniudn.com/gogopher.jpg?imageMogr/v2/thumbnail/100x200!
- (NSString *)qnScaleToFill:(CGSize)size;

//从图片中心裁剪成size大小
//http://qiniuphotos.qiniudn.com/gogopher.jpg?imageMogr/v2/gravity/center/crop/!256x256
- (NSString *)qnCropFromCenterToSize:(CGSize)size;
@end
