**中文版** | [English Version](README-en.md)

# CXDownload

实现Swift断点续传下载，支持Objective-C。包含大文件下载，后台下载，杀死进程，重新启动时继续下载，设置下载并发数，监听网络改变等。

[![Version](https://img.shields.io/cocoapods/v/CXDownload.svg?style=flat)](https://cocoapods.org/pods/CXDownload)
[![License](https://img.shields.io/cocoapods/l/CXDownload.svg?style=flat)](https://cocoapods.org/pods/CXDownload)
[![Platform](https://img.shields.io/cocoapods/p/CXDownload.svg?style=flat)](https://cocoapods.org/pods/CXDownload)

## 预览

<div align=left>
&emsp; <img src="https://github.com/itenfay/CXDownload/raw/master/IMG_0686.gif" width="50%" />
</div>

> **如果觉得还行呢，就麻烦顺手给个`star`。**

## 说明

- CXDownloadManager.swift: **下载任务处理管理**
- CXDownloadTaskProcessor.swift: **下载任务处理**
- CXDownloadModel.swift: **下载模型**
- CXDownloadDatabaseManager.swift: **下载数据库管理**
- FileUtils.swift: **文件工具**
- Logger.swift: **日志输出**
- StringEx.swift: **String扩展cxd_md5、cxd_sha2属性**
- ...

## 安装

`CXDownload`可通过 [CocoaPods](https://cocoapods.org) 获得。安装只需将下面一行添加到您的Podfile中:

```ruby
pod 'CXDownload'
```

## 使用

> 注意：为了更好的理解使用，请查看工程示例。

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
CXDownloadManager.shared.download(url: urls[0])
```

```
downloadButton1.dl.download(url: urls[0])
```

- 自定义下载目录和文件名

```
CXDownloadManager.shared.download(url: urls[1], toDirectory: "Softwares", fileName: "MacDict_v1.20.30.dmg")
```

```
downloadButton2.dl.download(url: urls[1], toDirectory: "Softwares", fileName: "MacDict_v1.20.30.dmg")
```

### 暂停

```
CXDownloadManager.shared.pause(url: urls[0])
```

```
pauseButton1.dl.pauseTask(url: urls[0])
```

### 取消

```
CXDownloadManager.shared.cancel(url: urls[0])
```

```
cancelButton1.dl.cancelTask(url: urls[0])
```

### 删除下载文件

```
CXDownloadManager.shared.deleteTaskAndCache(url: urls[0])
CXDownloadManager.shared.deleteTaskAndCache(url: urls[1], atDirectory: "Softwares", fileName: "MacDict_v1.20.30.dmg")
```

```
deleteButton1.dl.deleteTaskAndCache(url: urls[0])
deleteButton2.dl.deleteTaskAndCache(url: urls[1], atDirectory: "Softwares", fileName: "MacDict_v1.20.30.dmg")
```

## 推荐

- [FireKylin](https://github.com/itenfay/FireKylin) - `FireKylin`提供了许多Swift语言实用工具和丰富的扩展。
- [MarsUIKit](https://github.com/itenfay/MarsUIKit) - `MarsUIKit` wraps some commonly used UI components.
- [RxListDataSource](https://github.com/itenfay/RxListDataSource) - `RxListDataSource` provides data sources for UITableView or UICollectionView.
- [CXNetwork-Moya](https://github.com/itenfay/CXNetwork-Moya) - `CXNetwork-Moya` encapsulates a network request library with Moya and ObjectMapper.

## 示例项目

要运行示例项目，首先克隆repo，并从示例目录运行“pod install”。

## 许可证

`CXDownload`在MIT许可下可用。有关更多信息，请参见许可证文件。

## 欢迎反馈

如果您发现任何问题，请创建问题。我很乐意帮助你。
