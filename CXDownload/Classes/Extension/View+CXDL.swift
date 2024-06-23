//
//  View+CXDL.swift
//  CXDownload
//
//  Created by Tenfay on 2022/8/20.
//

import Foundation
#if os(iOS) || os(tvOS) || os(macOS)
#if os(iOS) || os(tvOS)
import UIKit
#else
import AppKit
#endif

extension CXDownloadBase where T : CXDView {
    
    /// Pauses the download task through a specified url.
    public func pauseTask(url: String) {
        CXDownloadManager.shared.pause(url: url)
    }
    
    /// Cancels the download task through a specified url.
    public func cancelTask(url: String) {
        CXDownloadManager.shared.cancel(url: url)
    }
    
    /// Deletes the task, cache, target file through the specified url, target directory and custom filename..
    public func deleteTaskAndCache(url: String, atDirectory directory: String? = nil, fileName: String? = nil) {
        CXDownloadManager.shared.deleteTaskAndCache(url: url, atDirectory: directory, fileName: fileName)
    }
    
}

#endif
