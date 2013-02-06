---
title: iOS SDK | 七牛云存储
---

# iOS SDK

- iOS SDK 下载地址：<https://github.com/qiniu/ios-sdk/tags>
- iOS SDK 源码地址：<https://github.com/qiniu/ios-sdk> (请注意非 master 分支的代码在规格上可能承受变更)

本SDK目前只提供了一个简单版本的上传功能，在类QiniuSimpleUploader中实现。

## QiniuSimpleUploader

QiniuSimpleUploader类提供了简单易用的iOS端文件上传功能。它的基本用法非常简单：

	// 创建一个QiniuSimpleUploader实例。
	// 需要保持这个变量，以便于用户取消某一个上传过程，通常创建的实例会保存为ViewController的成员变量。
	_uploader = [[QiniuSimpleUploader uploaderWithToken:[self tokenWithScope:bucket]] retain];
	
	// 设置消息器，消息接收器必须实现接口QiniuUploadDelegate。	
	_uploader.delegate = self;
  
	// 开始上传  
	[_uploader upload:filePath bucket:bucket key:key extraParams:nil];
	
如本例所示，如果我们需要保持该实例，我们需要手动的调用retain和release来避免内存出错或泄漏。

### 关于extraParams

一般情况下，开发者可以忽略upload方法中的extraParams参数，即在调用时保持extraParams的值为nil即可。但对于一些特殊的场景，我们可以给extraParams传入一些高级选项以更精确的控制上传行为。

extraParams是一个NSDictionary类型，upload方法会检查该字典中是否存在预定义的一些键，若有则添加到发送给服务器的请求中。预定义的键名在QiniuSimpleUploader.h的顶部，当前包含kMimeTypeKey、kCustomMetaKey、kCrc32Key、kCallbackParamsKey。

#### kMimeTypeKey

为上传的文件设置一个自定义的MIME类型。具体参见[http://docs.qiniutek.com/v3/api/words/#EncodedMimeType](http://docs.qiniutek.com/v3/api/words/#EncodedMimeType)。

#### kCustomMetaKey

自定义文本信息，可用于备注。通常不使用。

#### kCrc32Key

文件的CRC32校验值。如果设置了该可选参数，服务端会对上传的文件进行CRC32校验，如果校验失败会返回406错误。

以下是一个校验小文件CRC的例子：

	NSData *buffer = [NSData dataWithContentsOfFile:_filePath];
    
    uLong crc = crc32(0L, Z_NULL, 0);
    crc = crc32(crc, [buffer bytes], [buffer length]);
    
    NSString *crcStr = [NSString stringWithFormat:@"%lu", crc];

    NSDictionary *params = [NSDictionary dictionaryWithObjectsAndKeys:crcStr, kCrc32Key, nil];
    
    [uploader upload:_filePath bucket:kBucketName key:[NSString stringWithFormat:@"test-%@.png", timeDesc] extraParams:params];

这个例子直接在内存中对整个文件进行CRC校验，不适合大文件的CRC计算。如果需要计算大文件的CRC32，可以参照zlib.h中建议的做法，伪代码如下：

	 // zlib.h

     uLong crc = crc32(0L, Z_NULL, 0);

     while (read_buffer(buffer, length) != EOF) {
       crc = crc32(crc, buffer, length);
     }
     if (crc != original_crc) error();

#### kCallbackParamsKey

用于文件上传成功后执行回调，七牛云存储服务器会向客户方的业务服务器 POST 这些指定的参数。关于该参数的细节，请参见[http://docs.qiniutek.com/v3/api/words/#EncodedMimeType](http://docs.qiniutek.com/v3/api/words/#EncodedMimeType)中关于params的描述。

另外，虽然params支持JSON和URL参数两种格式，由于在客户端无法直接从token字符串中提取callbackBodyType信息，我们目前暂时只实现了URL参数格式，即如下所示：

	bucket=<BucketName>&key=<FileUniqKey>&uid=<customer
	
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

如果以静态链接库的方式使用该SDK，请注意您的工程设置中需要设置-ObjC标志，这是因为该SDK中使用了Objective-C category功能来实现JSON字符串的序列化和反序列化，而没有-ObjC标志的话Objective-C category功能将不能正常工作，错误表现为直接异常退出。

另外，由于QiniuSimpleUploader采用的是单次HTTP请求发送整个文件内容的方法，因此并不适合用于上传大尺寸的文件。如果您有这方面的需求，请[联系我们](https://dev.qiniutek.com/feedback)。我们稍后也会在SDK中增加支持断点续传的上传类。


<a name="Contributing"></a>

## 贡献代码

七牛云存储 iOS SDK 源码地址：<https://github.com/qiniu/ios-sdk>

1. 登录 [github.com](https://github.com)
2. Fork <https://github.com/qiniu/ios-sdk>
3. 创建您的特性分支 (`git checkout -b my-new-feature`)
4. 提交您的改动 (`git commit -am 'Added some feature'`)
5. 将您的改动记录提交到远程 `git` 仓库 (`git push origin my-new-feature`)
6. 然后到 github 网站的该 `git` 远程仓库的 `my-new-feature` 分支下发起 Pull Request

<a name="License"></a>

## 许可证

Copyright (c) 2012-2013 qiniutek.com
