# CXDownload

Implements Swift breakpoint continuation download.

[![CI Status](https://img.shields.io/travis/chenxing640/CXDownload.svg?style=flat)](https://travis-ci.org/chenxing640/CXDownload)
[![Version](https://img.shields.io/cocoapods/v/CXDownload.svg?style=flat)](https://cocoapods.org/pods/CXDownload)
[![License](https://img.shields.io/cocoapods/l/CXDownload.svg?style=flat)](https://cocoapods.org/pods/CXDownload)
[![Platform](https://img.shields.io/cocoapods/p/CXDownload.svg?style=flat)](https://cocoapods.org/pods/CXDownload)

## Example

To run the example project, clone the repo, and run `pod install` from the Example directory first.

## Installation

CXDownload is available through [CocoaPods](https://cocoapods.org). To install
it, simply add the following line to your Podfile:

```ruby
pod 'CXDownload'
```

## Explanation

- CXDownloadManager.swift: **The Download network request queue management class.**
- CXDownloadTaskProcessor.swift: **The Download network sending and receiving class.**
- CXDownloadModel.swift: **The Download model class.**
- CXDownloadDatabaseManager.swift: **The Download database manager class.**
- FileUtils.swift: **The file tool class.**
- Logger.swift: **This class outputs the log to the console.**
- String+Cx.swift: **This extends the `cx_md5`, `cxd_sha2` properties for the `String` class.**

## Usage

### Download

- Monitor download status and progress

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

- Default download directory and file name.

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

- Custom download directory and file name.

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

### Pause

```
CXDownloadManager.shared.pause(url: urlStr1)
```

```dl
pauseButton1.dl.pauseTask(url: urlStr1)
```

### Cancel

```
CXDownloadManager.shared.cancel(url: urlStr1)
```

```dl
cancelButton1.dl.cancelTask(url: urlStr1)
```

### Delete target file

```
CXDownloadManager.shared.deleteTaskAndCache(url: urlStr1)
CXDownloadManager.shared.deleteTaskAndCache(url: urlStr2, atDirectory: "Softwares", fileName: "MacDict_v1.20.30.dmg")
```

```dl
deleteButton1.dl.deleteTaskAndCache(url: urlStr1)
deleteButton2.dl.deleteTaskAndCache(url: urlStr2, atDirectory: "Softwares", fileName: "MacDict_v1.20.30.dmg")
```

## License

CXDownload is available under the MIT license. See the LICENSE file for more info.
