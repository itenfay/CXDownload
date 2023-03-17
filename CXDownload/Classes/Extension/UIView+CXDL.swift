//
//  UIView+CXDL.swift
//  CXDownload
//
//  Created by chenxing on 2022/8/20.
//

import Foundation

extension CXDownloadBase where T : UIView {
    
    /// Resumes the download task through a specified url.
    public func resume(url: String) {
        CXDownloaderManager.shared.resume(with: url)
    }
    
    /// Pauses the download task through a specified url.
    public func pause(url: String) {
        CXDownloaderManager.shared.pause(with: url)
    }
    
    /// Cancels the download task through a specified url.
    public func cancel(url: String) {
        CXDownloaderManager.shared.cancel(with: url)
    }
    
    /// Removes the target file through a specified url, the target directory and the custom filename.
    public func removeTargetFile(url: String, at targetDirectory: String? = nil, customFileName: String? = nil) {
        CXDownloaderManager.shared.removeTargetFile(url: url, customDirectory: targetDirectory, customFileName: customFileName)
    }
    
}
