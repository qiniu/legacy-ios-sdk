## CHANGE LOG

### v6.3.0

- [#77] 多host上传重试
- [#79] 支持NSData 上传

### v6.2.8

- [#74] fop url escape
- [#75] 统一user agent 格式

### v6.2.7

- [#63] 添加额外错误信息
- [#64] mkfile 支持 key 为 nil
- [#65] 修正 传入的blockComplete在第一次运行的退出时被释放，如果失败重试会变成nil，导致出错
- [#70] 修改上传域名为upload.qiniu.com
- [#72] operation.responseObject 返回增加nil 判断

### v6.2.6

- [#61] 错误信息增加reqid

### v6.2.5

- [#50] update AFN 2.2.3
- [#52] bugfix: 701 retry

### v6.2.2

2014-04-09 issue [#44](https://github.com/qiniu/ios-sdk/pull/44)

- [#43] AFNetworking升级到2.2.1

### v6.2.1

2014-04-03 issue [#41](https://github.com/qiniu/ios-sdk/pull/41)

- [#28] NSString qiniu category
- [#38] 更新配置，引入Travis
- [#39] bugfix 增加@optional 调用时的判断

### v6.2.0

2014-03-04 issue [#37](https://github.com/qiniu/ios-sdk/pull/37)

- Replace ASIHttpRequest with AFNetwork2.0.3
- 老的基于 ASIHttpRequest 的代码，建立了 ASIHttpRequest 分支，独立演化。


### v6.0.0

2013-07-04 issue [#17](https://github.com/qiniu/ios-sdk/pull/17)

- 遵循 [sdkspec v6.0.3](https://github.com/qiniu/sdkspec/tree/v6.0.3)。


### v3.3.0

2013-06-28 issue [#14](https://github.com/qiniu/ios-sdk/pull/14)

- error 类型增加 `X-Log`, `X-Reqid`。

