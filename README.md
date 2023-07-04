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
- CXDownloadTaskProcessor.swift: **下载网络收发**
- CXDFileUtils.swift: **断点续传文件工具类**
- CXDLogger.swift: **日志输出类**
- StringEx.swift: **String扩展cxd_md5、cxd_sha2属性**

## 使用

### 下载

- 默认下载目录和文件名

```
_ = CXDownloadManager.shared.asyncDownload(url: urlStr1) { [weak self] progress in
    DispatchQueue.main.async {
        self?.progressLabel1.text = "\(Int(progress * 100)) %"
    }
} success: { filePath in
    CXDLogger.log(message: "filePath: \(filePath)", level: .info)
} failure: { error in
    switch error {
        case .error(let code, let message):
            CXDLogger.log(message: "error: \(code), message: \(message)", level: .info)
    }
}
```

```dl
let downloader = downloadButton1.dl.download(url: urlStr1) { [weak self] progress in
    self?.progressLabel1.text = "\(progress) %"
} success: { filePath in
    CXDLogger.log(message: "filePath: \(filePath)", level: .info)
} failure: { error in
    switch error {
    case .error(let code, let message):
        CXDLogger.log(message: "error: \(code), message: \(message)", level: .info)
    }
}
if let _downloader = downloader {
    if _downloader.state == .pause {
        _downloader.resume()
        pauseButton1.isSelected = false
    }
}
```

- 自定义下载目录和文件名

```
_ = CXDownloadManager.shared.asyncDownload(url: urlStr2, customDirectory: "Softwares", customFileName: "MacDict_v1.20.30.dmg") { [weak self] progress in
    DispatchQueue.main.async {
        self?.progressLabel2.text = "\(Int(progress * 100)) %"
    }
} success: { filePath in
    CXDLogger.log(message: "filePath: \(filePath)", level: .info)
} failure: { error in
    switch error {
        case .error(let code, let message):
            CXDLogger.log(message: "error: \(code), message: \(message)", level: .info)
    }
}
```

```dl
let downloader = downloadButton2.dl.download(url: urlStr1, to: "Softwares", customFileName: "MacDict_v1.20.30.dmg") { [weak self] progress in
    self?.progressLabel1.text = "\(progress) %"
} success: { filePath in
    CXDLogger.log(message: "filePath: \(filePath)", level: .info)
} failure: { error in
    switch error {
    case .error(let code, let message):
        CXDLogger.log(message: "error: \(code), message: \(message)", level: .info)
    }
}
if let _downloader = downloader {
    if _downloader.state == .pause {
        _downloader.resume()
        pauseButton1.isSelected = false
    }
}
```

### 暂停

```
CXDownloadManager.shared.pause(with: urlStr1)
```

```dl
pauseButton1.dl.pause(url: urlStr1)
```

### 恢复

```
CXDownloadManager.shared.resume(with: urlStr1)
```

```dl
pauseButton1.dl.resume(url: urlStr1)
```

### 取消

```
CXDownloadManager.shared.cancel(with: urlStr1)
```

```dl
cancelButton1.dl.cancel(url: urlStr1)
```

### 删除下载文件

```
CXDownloadManager.shared.removeTargetFile(url: urlStr1)
CXDownloadManager.shared.removeTargetFile(url: urlStr2, customDirectory: "Softwares", customFileName: "MacDict_v1.20.30.dmg")
```

```dl
deleteButton1.dl.removeTargetFile(url: urlStr1)
deleteButton2.dl.removeTargetFile(url: urlStr2, at: "Softwares", customFileName: "MacDict_v1.20.30.dmg")
```

### 暂停、恢复和取消所有下载

```
CXDownloadManager.shared.pauseAll()
CXDownloadManager.shared.resumeAll()
CXDownloadManager.shared.cancelAll()
```

## 许可证

CXDownload在MIT许可下可用。有关更多信息，请参见许可证文件。
