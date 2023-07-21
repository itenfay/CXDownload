[中文版](README.md) | **English Version**

# CXDownload

Realization of breakpoint transmission download with Swift, support Objective-C. Including large file download, background download, killing the process, continuing to download when restarting, setting the number of concurrent downloads, monitoring network changes and so on.

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

## Preview

<div align=left>
&emsp; <img src="https://github.com/chenxing640/CXDownload/raw/master/IMG_0686.gif" width="90%" />
</div>

## Explanation

- CXDownloadManager.swift: **The download task management**
- CXDownloadTaskProcessor.swift: **The download task processor**
- CXDownloadModel.swift: **The download model**
- CXDownloadDatabaseManager.swift: **The download database management**
- FileUtils.swift: **The file tool**
- Logger.swift: **This outputs the log to the console**
- String+Cx.swift: **This extends the `cx_md5`, `cxd_sha2` properties for `String`**
- ...

## Usage

> Note: In order to better understand the usages, please check the engineering example.

### Monitor download status and progress

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

### Download

- Default download directory and file name.

```
CXDownloadManager.shared.download(url: urlStr1)
```

```dl
downloadButton1.dl.download(url: urlStr1)
```

- Custom download directory and file name.

```
CXDownloadManager.shared.download(url: urlStr2, toDirectory: "Softwares", fileName: "MacDict_v1.20.30.dmg")
```

```dl
downloadButton2.dl.download(url: urlStr2, toDirectory: "Softwares", fileName: "MacDict_v1.20.30.dmg") 
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

## Author

chenxing, chenxing640@foxmail.com

## License

CXDownload is available under the MIT license. See the LICENSE file for more info.
