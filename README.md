# CXDownload

实现Swift断点续传下载。

[![CI Status](https://img.shields.io/travis/chenxing640/CXDownload.svg?style=flat)](https://travis-ci.org/chenxing640/CXDownload)
[![Version](https://img.shields.io/cocoapods/v/CXDownload.svg?style=flat)](https://cocoapods.org/pods/CXDownload)
[![License](https://img.shields.io/cocoapods/l/CXDownload.svg?style=flat)](https://cocoapods.org/pods/CXDownload)
[![Platform](https://img.shields.io/cocoapods/p/CXDownload.svg?style=flat)](https://cocoapods.org/pods/CXDownload)

[English Instructions (EN)](README-en.md).

## 示例项目

要运行示例项目，首先克隆repo，并从示例目录运行“pod install”。

## 安装

CXDownload可通过 [CocoaPods](https://cocoapods.org) 获得。安装
只需将下面一行添加到您的Podfile中:

```ruby
pod 'CXDownload'
```

## 说明

- CXDownloadManager.swift: **下载网络请求队列管理类**
- CXDownloadTaskProcessor.swift: **下载任务处理类**
- CXDownloadModel.swift: **下载模型类**
- CXDownloadDatabaseManager.swift: **下载数据库管理类**
- FileUtils.swift: **断点续传文件工具类**
- Logger.swift: **日志输出类**
- StringEx.swift: **String扩展cxd_md5、cxd_sha2属性**

## 使用

### 下载

- 默认下载目录和文件名

```
CXDownloadManager.shared.download(url: urlStr1) { [weak self] model in
    self?.progressLabel1.text = "\(Int(model.progress * 100)) %"
} success: { model in
    CXDLogger.log(message: "filePath: \(model.localPath ?? "")", level: .info)
} failure: { model in
    if let stateInfo = model.stateInfo {
        CXDLogger.log(message: "error: \(stateInfo.code), message: \(stateInfo.message)", level: .info)
    }
}
```

```dl
downloadButton1.dl.download(url: urlStr1) { [weak self] model in
    self?.progressLabel1.text = "\(Int(model.progress * 100)) %"
} success: { model in
    CXDLogger.log(message: "filePath: \(model.localPath ?? "")", level: .info)
} failure: {  model in
    if let stateInfo = model.stateInfo {
        CXDLogger.log(message: "error: \(stateInfo.code), message: \(stateInfo.message)", level: .info)
    }
}
```

- 自定义下载目录和文件名

```
CXDownloadManager.shared.download(url: urlStr2, toDirectory: "Softwares", fileName: "MacDict_v1.20.30.dmg") { [weak self] model in
    self?.progressLabel2.text = "\(Int(model.progress * 100)) %"
} success: { model in
    CXDLogger.log(message: "filePath: \(model.localPath ?? "")", level: .info)
} failure: { model in
    if let stateInfo = model.stateInfo {
        CXDLogger.log(message: "error: \(stateInfo.code), message: \(stateInfo.message)", level: .info)
    }
}
```

```dl
downloadButton2.dl.download(url: urlStr2, toDirectory: "Softwares", fileName: "MacDict_v1.20.30.dmg") { [weak self] model in
    self?.progressLabel2.text = "\(Int(model.progress * 100)) %"
} success: { model in
    CXDLogger.log(message: "filePath: \(model.localPath ?? "")", level: .info)
} failure: {  model in
    if let stateInfo = model.stateInfo {
        CXDLogger.log(message: "error: \(stateInfo.code), message: \(stateInfo.message)", level: .info)
    }
}
```

### 暂停

```
CXDownloadManager.shared.pause(url: urlStr1)
```

```dl
pauseButton1.dl.pauseTask(url: urlStr1)
```

### 取消

```
CXDownloadManager.shared.cancel(url: urlStr1)
```

```dl
cancelButton1.dl.cancelTask(url: urlStr1)
```

### 删除下载文件

```
CXDownloadManager.shared.deleteTaskAndCache(url: urlStr1)
CXDownloadManager.shared.deleteTaskAndCache(url: urlStr2, atDirectory: "Softwares", fileName: "MacDict_v1.20.30.dmg")
```

```dl
deleteButton1.dl.deleteTaskAndCache(url: urlStr1)
deleteButton2.dl.deleteTaskAndCache(url: urlStr2, atDirectory: "Softwares", fileName: "MacDict_v1.20.30.dmg")
```

## 许可证

CXDownload在MIT许可下可用。有关更多信息，请参见许可证文件。
