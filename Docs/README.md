---
title: iOS SDK
---

# iOS SDK 使用指南

- iOS SDK 下载地址：<https://github.com/qiniu/ios-sdk/tags>
- iOS SDK 源码地址：<https://github.com/qiniu/ios-sdk> (请注意非 master 分支的代码在规格上可能承受变更)

本SDK目前只提供了一个简单版本的上传功能，在类QiniuSimpleUploader中实现。

## QiniuSimpleUploader

QiniuSimpleUploader 类提供了简单易用的iOS端文件上传功能。它的基本用法非常简单：

	// 创建一个QiniuSimpleUploader实例。
	// 需要保持这个变量，以便于用户取消某一个上传过程，通常创建的实例会保存为ViewController的成员变量。
	uploader = [[QiniuSimpleUploader uploaderWithToken:[self tokenWithScope:bucket]] retain];

	// 设置消息器，消息接收器必须实现接口QiniuUploadDelegate。
	uploader.delegate = self;

	// 开始上传
	[uploader uploadFile:filePath key:key extra:nil];

**注意： key必须采用utf8编码，如使用非utf8编码访问七牛云存储将反馈错误**

如本例所示，如果我们需要保持该实例，我们需要手动的调用retain和release来避免内存出错或泄漏。

### 关于extra参数

一般情况下，开发者可以忽略 uploadFile 方法中的 extra 参数，即在调用时保持 extra 的值为 nil 即可。但对于一些特殊的场景，我们可以给 extra 传入一些高级选项以更精确的控制上传行为。

extra 是一个 QiniuPutExtra 类型，其中包含变量：params，mimeType，crc32，checkCrc。

#### mimeType

为上传的文件设置一个自定义的 MIME 类型，如果为空，那么服务端自动检测文件的 MIME 类型。

#### crc32 checkCrc

checkCrc 为 0 时，服务端不会校验 crc32 值，checkCrc 为 1 时，服务端会计算上传文件的 crc32 值，然后与用户提供的 crc32 参数值相比较确认文件的完整性，如果校验失败会返回 406 错误。

以下是一个校验小文件 CRC 的例子：

	// calc right crc32 value
    NSData *buffer = [NSData dataWithContentsOfFile:_filePath];
    uLong crc = crc32(0L, Z_NULL, 0);
    crc = crc32(crc, [buffer bytes], [buffer length]);

    // extra argument with right crc32
    QiniuPutExtra *extra = [[[QiniuPutExtra alloc] init] autorelease];
    extra.crc32 = crc;
    extra.checkCrc = 1;

    // upload
    [uploader uploadFile:_filePath key:@"test.png" extra:extra];

这个例子直接在内存中对整个文件进行 CRC 校验，不适合大文件的 CRC 计算。如果需要计算大文件的 CRC32，可以参照 zlib.h 中建议的做法，伪代码如下：

	 // zlib.h

     uLong crc = crc32(0L, Z_NULL, 0);

     while (read_buffer(buffer, length) != EOF) {
       crc = crc32(crc, buffer, length);
     }
     if (crc != original_crc) error();

#### params

用户自定义参数，必须以 "x:" 开头，这些参数可以作为变量用于 upToken 的 callbackBody，returnBody，asyncOps 参数中，具体见：http://docs.qiniu.com/api/put.html#xVariables。简单的一个例子为：

	// extra argument
    QiniuPutExtra *extra = [[[QiniuPutExtra alloc] init] autorelease];
    extra.params = @{@"x:foo": @"fooName"};

    // upload
    [uploader uploadFile:_filePath key:@"test.png" extra:extra];

## QiniuUploadDelegate

这个 delegate 接口由调用者实现，以获取上传的结果和进度信息。

	@protocol QiniuUploadDelegate <NSObject>

	@optional

	// Progress updated. 1.0 indicates 100%.
	- (void)uploadProgressUpdated:(NSString *)filePath percent:(float)percent;

	@required

	// Upload completed successfully.
	- (void)uploadSucceeded:(NSString *)filePath ret:(NSDictionary *)ret;

	// Upload failed.
	- (void)uploadFailed:(NSString *)filePath error:(NSError *)error;

	@end

当上传成功后返回的数据都放在 NSDictionary 类型中，比如 hash 值。当用户将 key 赋值为 kQiniuUndefinedKey(?)时，会返回自动生成的 key，当用户在 upToken 中指定了 returnBody 时会返回用户自定义的内容。

该接口包含了两个必须实现的方法和一个可选的方法。我们可以选择由 ViewController 直接实现，类似于如下：

	@interface QiniuViewController : UIViewController<QiniuUploadDelegate, …>

## 使用方法

因为当前的SDK只包含了很少的源文件，为避免需要管理工程依赖关系，开发者完全可以直接将所提供的这几个文件直接添加到自己的工程中，当然，也需要添加对应的依赖包：AFNetworking。

本SDK附带的QiniuDemo是以静态库的方式使用QiniuSDK。如果开发者希望用这种方式引入QiniuSDK，可以借鉴一下QiniuDemo的工程设置。

运行QiniuDemo之前需要先设置代码中的三个配置项：QiniuAccessKey、QiniuSecretKey 和 QiniuBucketName。相应的值都可以在我们的[开发者平台]( https://portal.qiniu.com/)上操作和获取。

## 注意事项

如果以静态链接库的方式使用该SDK，请注意您的工程设置中需要设置-ObjC标志，这是因为该SDK中使用了Objective-C category功能来实现JSON字符串的序列化和反序列化，而没有-ObjC标志的话Objective-C category功能将不能正常工作，错误表现为直接异常退出。

另外，由于QiniuSimpleUploader采用的是单次HTTP请求发送整个文件内容的方法，因此并不适合用于上传大尺寸的文件。如果您有这方面的需求，请[联系我们](http://support.qiniu.com/home)。我们稍后也会在SDK中增加支持断点续传的上传类。

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

Copyright (c) 2012-2014 qiniu.com
