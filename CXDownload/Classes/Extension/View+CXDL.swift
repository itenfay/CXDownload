//
//  View+CXDL.swift
//  CXDownload
//
//  Created by chenxing on 2022/8/20.
//

import Foundation
#if os(iOS) || os(tvOS) || os(macOS)
#if os(iOS) || os(tvOS)
import UIKit
#else
import AppKit
#endif

extension CXDownloadBase where T : CXDView {
    
    /// Resumes the download task through a specified url.
    public func resume(url: String) {
        CXDownloadManager.shared.resume(with: url)
    }
    
    /// Pauses the download task through a specified url.
    public func pause(url: String) {
        CXDownloadManager.shared.pause(with: url)
    }
    
    /// Cancels the download task through a specified url.
    public func cancel(url: String) {
        CXDownloadManager.shared.cancel(with: url)
    }
    
    /// Removes the target file through a specified url, the target directory and the custom filename.
    public func removeTargetFile(url: String, at targetDirectory: String? = nil, customFileName: String? = nil) {
        CXDownloadManager.shared.removeTargetFile(url: url, customDirectory: targetDirectory, customFileName: customFileName)
    }
    
}

#endif
