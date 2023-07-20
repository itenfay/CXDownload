**中文版** | [English Version](README-en.md)

# CXDownload

实现Swift断点续传下载，支持Objective-C。

[![Version](https://img.shields.io/cocoapods/v/CXDownload.svg?style=flat)](https://cocoapods.org/pods/CXDownload)
[![License](https://img.shields.io/cocoapods/l/CXDownload.svg?style=flat)](https://cocoapods.org/pods/CXDownload)
[![Platform](https://img.shields.io/cocoapods/p/CXDownload.svg?style=flat)](https://cocoapods.org/pods/CXDownload)

## 示例项目

要运行示例项目，首先克隆repo，并从示例目录运行“pod install”。

## 安装

CXDownload可通过 [CocoaPods](https://cocoapods.org) 获得。安装
只需将下面一行添加到您的Podfile中:

```ruby
pod 'CXDownload'
```

## 说明

- CXDownloadManager.swift: **下载网络请求任务管理**
- CXDownloadTaskProcessor.swift: **下载任务处理**
- CXDownloadModel.swift: **下载模型**
- CXDownloadDatabaseManager.swift: **下载数据库管理**
- FileUtils.swift: **文件工具**
- Logger.swift: **日志输出**
- StringEx.swift: **String扩展cxd_md5、cxd_sha2属性**
- ...

## 使用

> 注意：为了更好的理解使用，请查看工程例子。

### 监听下载状态和进度

```
func addNotification() {
    NotificationCenter.default.addObserver(self, selector: #selector(downloadStateChange(_:)), name: CXDownloadConfig.stateChangeNotification, object: nil)
    NotificationCenter.default.addObserver(self, selector: #selector(downloadProgressChange(_:)), name: CXDownloadConfig.progressNotification, object: nil)
}

@objc func downloadStateChange(_ noti: Notification) {
    guard let downloadModel = noti.object as? CXDownloadModel else {
        return
    }
    if downloadModel.state == .finish {
        CXDLogger.log(message: "filePath: \(downloadModel.localPath ?? "")", level: .info)
    } else if downloadModel.state == .error || downloadModel.state == .cancelled {
        if let stateInfo = downloadModel.stateInfo {
            CXDLogger.log(message: "error: \(stateInfo.code), message: \(stateInfo.message)", level: .info)
        }
    }
}

@objc func downloadProgressChange(_ noti: Notification) {
    guard let downloadModel = noti.object as? CXDownloadModel else {
        return
    }
    CXDLogger.log(message: "[\(downloadModel.url)] \(Int(downloadModel.progress * 100)) %", level: .info)
}
```

### 下载

- 默认下载目录和文件名

```
CXDownloadManager.shared.download(url: urlStr1)
```

```dl
downloadButton1.dl.download(url: urlStr1)
```

- 自定义下载目录和文件名

```
CXDownloadManager.shared.download(url: urlStr2, toDirectory: "Softwares", fileName: "MacDict_v1.20.30.dmg")
```

```dl
downloadButton2.dl.download(url: urlStr2, toDirectory: "Softwares", fileName: "MacDict_v1.20.30.dmg")
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

## 作者

chenxing, chenxing640@foxmail.com

## 许可证

CXDownload在MIT许可下可用。有关更多信息，请参见许可证文件。
