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

- CXDownloaderManager.swift: **Download network request queue management class.**
- CXDownloader.swift: **Download network sending and receiving class.**
- CXFileUtils.swift: **Breakpoint continuation file tool class.**
- CXLogger.swift: **This class outputs the log to the console.**
- String+Cx.swift: **This extends the `cx_md5` property for the `String` class.**

## Usage

### Download

- Default download directory and file name.

```
_ = CXDownloaderManager.shared.asyncDownload(url: urlStr1) { [weak self] progress in
    DispatchQueue.main.async {
        self?.progressLabel1.text = "\(Int(progress * 100)) %"
    }
} success: { filePath in
    CXLogger.log(message: "filePath: \(filePath)", level: .info)
} failure: { error in
    switch error {
        case .error(let code, let message):
            CXLogger.log(message: "error: \(code), message: \(message)", level: .info)
    }
}
```

```dl
let downloader = downloadButton1.dl.download(url: urlStr1) { [weak self] progress in
    self?.progressLabel1.text = "\(progress) %"
} success: { filePath in
    CXLogger.log(message: "filePath: \(filePath)", level: .info)
} failure: { error in
    switch error {
    case .error(let code, let message):
        CXLogger.log(message: "error: \(code), message: \(message)", level: .info)
    }
}
if let _downloader = downloader {
    if _downloader.state == .pause {
        _downloader.resume()
        pauseButton1.isSelected = false
    }
}
```

- Custom download directory and file name.

```
_ = CXDownloaderManager.shared.asyncDownload(url: urlStr2, customDirectory: "Softwares", customFileName: "MacDict_v1.20.30.dmg") { [weak self] progress in
    DispatchQueue.main.async {
        self?.progressLabel2.text = "\(Int(progress * 100)) %"
    }
} success: { filePath in
    CXLogger.log(message: "filePath: \(filePath)", level: .info)
} failure: { error in
    switch error {
        case .error(let code, let message):
            CXLogger.log(message: "error: \(code), message: \(message)", level: .info)
    }
}
```

```dl
let downloader = downloadButton2.dl.download(url: urlStr1, to: "Softwares", customFileName: "MacDict_v1.20.30.dmg") { [weak self] progress in
    self?.progressLabel1.text = "\(progress) %"
} success: { filePath in
    CXLogger.log(message: "filePath: \(filePath)", level: .info)
} failure: { error in
    switch error {
    case .error(let code, let message):
        CXLogger.log(message: "error: \(code), message: \(message)", level: .info)
    }
}
if let _downloader = downloader {
    if _downloader.state == .pause {
        _downloader.resume()
        pauseButton1.isSelected = false
    }
}
```

### Pause

```
CXDownloaderManager.shared.pause(with: urlStr1)
```

```dl
pauseButton1.dl.pause(url: urlStr1)
```

### Resume

```
CXDownloaderManager.shared.resume(with: urlStr1)
```

```dl
pauseButton1.dl.resume(url: urlStr1)
```

### Cancel

```
CXDownloaderManager.shared.cancel(with: urlStr1)
```

```dl
cancelButton1.dl.cancel(url: urlStr1)
```


### Delete target file

```
CXDownloaderManager.shared.removeTargetFile(url: urlStr1)
CXDownloaderManager.shared.removeTargetFile(url: urlStr2, customDirectory: "Softwares", customFileName: "MacDict_v1.20.30.dmg")
```

```dl
deleteButton1.dl.removeTargetFile(url: urlStr1)
deleteButton2.dl.removeTargetFile(url: urlStr2, at: "Softwares", customFileName: "MacDict_v1.20.30.dmg")
```

### Pause, resume and cancell the all downloads

```
CXDownloaderManager.shared.pauseAll()
CXDownloaderManager.shared.resumeAll()
CXDownloaderManager.shared.cancelAll()
```

## License

CXDownload is available under the MIT license. See the LICENSE file for more info.
