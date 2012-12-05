---
title: Objective-C SDK | 七牛云存储
---

# Objective-C SDK

SDK下载地址：[https://github.com/qiniu/objc-sdk](https://github.com/qiniu/objc-sdk)

本SDK目前只提供了一个简单版本的上传功能，稍后会增加断点续传功能。

## QiniuSimpleUploader

QiniuSimpleUploader类提供了一个简单易用的iOS端文件上传功能。它的基本用法非常简单

	// 创建一个QiniuSimpleUploader实例。
	// 需要保持这个变量，以便于用户取消某一个上传过程，通常创建的实例会保存为ViewController的成员变量。
	_uploader = [[QiniuSimpleUploader uploaderWithToken:[self tokenWithScope:bucket]] retain];
	
	// 设置消息器，消息接收器必须实现接口QiniuUploadDelegate。	
	_uploader.delegate = self;
  
	// 开始上传  
	[_uploader upload:filePath bucket:bucket key:key extraParams:nil];
	
如本例所示，如果我们需要保持该实例，我们需要手动的调用retain和release来避免内存出错或泄漏。	
	
## QiniuResumableUploader

TODO。

## QiniuUploadDelegate

这个delegate接口由调用者实现，以获取上传的结果和进度信息。

	@protocol QiniuUploadDelegate <NSObject>

	@optional

	// Progress updated. 1.0 indicates 100%.
	- (void)uploadProgressUpdated:(NSString *)filePath percent:(float)percent;

	@required

	// Upload completed successfully.
	- (void)uploadSucceeded:(NSString *)filePath hash:(NSString *)hash;

	// Upload failed.
	- (void)uploadFailed:(NSString *)filePath error:(NSError *)error;

	@end

可以看到，该接口包含了两个必须实现的方法和一个可选的方法。我们可以选择由ViewController直接实现，类似于如下：

	@interface QiniuViewController : UIViewController<QiniuUploadDelegate, …>

这个接口可以被QiniuSimpleUploader和QiniuResumableUploader共用。因此对于当前使用QiniuSimpleUploader的开发者，之后换成QiniuResumableUploader将只需要调整极少的代码。

## 使用方法

因为当前的SDK只包含了3个.h文件和一个.m文件，为避免需要管理工程依赖关系，开发者完全可以直接将所提供的这几个文件直接添加到自己的工程中，当然，也需要添加对应的依赖包：JSONKit、ASIHttpRequest和GTMBase64。

本SDK附带的QiniuDemo是以静态库的方式使用QiniuSDK。如果开发者希望用这种方式引入QiniuSDK，可以借鉴一下QiniuDemo的工程设置。

运行QiniuDemo之前需要先设置代码中的三个常量：kAccessKey、kSecretKey和kBucketName。相应的值都可以在我们的[开发者平台](https://dev.qiniutek.com/)上操作和获取。
## 注意事项

如果以静态链接库的方式使用该SDK，请注意您的工程设置中需要设置-ObjC标志，这是因为该SDK中使用了Objective-C的Class Category功能来实现JSON字符串的序列化和反序列化，而没有-ObjC标志的话Class Category功能将不能正常工作。
