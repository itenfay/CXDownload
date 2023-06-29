//
//  CXDownloadManager.swift
//  CXDownload
//
//  Created by chenxing on 2022/8/15.
//

import Foundation

/// The state for the download.
@objc public enum CXDownloadState: Int, CustomStringConvertible {
    // Represents download state.
    case downloading, waiting, paused, cancelled, finish, error
    
    public var description: String {
        switch self {
        case .downloading: return "Downloading"
        case .waiting: return "Waiting"
        case .paused: return "Paused"
        case .cancelled: return "Cancelled"
        case .finish: return "Finish"
        case .error: return "Error"
        }
    }
}

typealias ProgressClosure = (_ progress: Float) -> Void
typealias SuccessClosure = (_ filePath: String) -> Void
typealias FailureClosure = (_ code: Int, _ message: String) -> Void
typealias FinishClosure = (_ url: String) -> Void
typealias StateChangeClosure = (_ state: CXDownloadState) -> Void

public class CXDownloadManager {
    
    /// Returns a singleton instance.
    public static let shared = CXDownloadManager()
    
    /// Privatizes the constructor.
    private init() {}
    
    /// The dictionary stores the downloader.
    private var downloaderDict: [String : CXDownloadProcessor] = [:]
    
    /// The configuration for the download.
    public struct Configuration {
        /// The max count for the download.
        public var maxDownloadCount: Int
    }
    
    /// Initializes an configuration instance, default log is enabled.
    public var configuration = Configuration(maxDownloadCount: 1)
    
    /// Executes an asynchronous download with the url and some callback closures.
    @discardableResult
    public func download(url: String, progress: @escaping ProgressClosure, success: @escaping SuccessClosure, failure: @escaping FailureClosure) -> CXDownloader? {
        guard let urlSha2 = url.cxd_sha2, !urlSha2.isEmpty else {
            CXDLogger.log(message: "The url md5 is empty.", level: .info)
            failure(CXDownloader.DownloadError.error(code: -1999, message: "The url md5 is empty."))
            return nil
        }
        //CXDLogger.log(message: "urlSha2: \(urlSha2)", level: .info)
        if let resultDict = downloaderDict.first(where: { $0.key == urlSha2 }) {
            let _downloader = resultDict.value
            CXDLogger.log(message: "Downloader: \(_downloader)", level: .info)
            return _downloader
        }
        // Creates a downloader instance.
        let downloader = CXDownloader.download(url: url,
                                               progess: progress,
                                               success: success,
                                               failure: failure) {
            [unowned self] urlString in
            if let key = urlString.cxd_sha2 {
                CXDLogger.log(message: "Remove key: \(key)", level: .info)
                self.downloaderDict.removeValue(forKey: key)
            }
        }
        downloaderDict[urlSha2] = downloader
        downloader.startDownloading()
        return downloader
    }
    
    /// Executes an asynchronous download with the url and some callback closures.
    @discardableResult
    public func download(url: String, customDirectory: String?, customFileName: String?, progress: @escaping CXDownloader.ProgressClosure, success: @escaping CXDownloader.SuccessClosure, failure: @escaping CXDownloader.FailureClosure) -> CXDownloader? {
        guard let urlSha2 = url.cxd_sha2, !urlSha2.isEmpty else {
            CXDLogger.log(message: "The url md5 is empty.", level: .info)
            failure(CXDownloader.DownloadError.error(code: -1999, message: "The url md5 is empty."))
            return nil
        }
        //CXDLogger.log(message: "urlSha2: \(urlSha2)", level: .info)
        if let resultDict = downloaderDict.first(where: { $0.key == urlSha2 }) {
            let _downloader = resultDict.value
            CXDLogger.log(message: "Downloader: \(_downloader)", level: .info)
            return _downloader
        }
        // Creates a downloader instance.
        let downloader = CXDownloader.download(url: url,
                                               customDirectory: customDirectory,
                                               customFileName: customFileName,
                                               progess: progress,
                                               success: success,
                                               failure: failure) {
            [unowned self] urlString in
            if let key = urlString.cxd_sha2 {
                CXDLogger.log(message: "Remove key: \(key)", level: .info)
                self.downloaderDict.removeValue(forKey: key)
            }
        }
        downloaderDict[urlSha2] = downloader
        downloader.startDownloading()
        return downloader
    }
    
    /// Resumes a download task through a specified url.
    public func resume(with url: String) {
        _ = downloaderDict.first {
            if $0.key == url.cxd_sha2 { $0.value.resume()
                return true
            } else { return false }
        }
    }
    
    /// Pauses a download task through a specified url.
    public func pause(with url: String) {
        _ = downloaderDict.first {
            if $0.key == url.cxd_sha2 { $0.value.pause()
                return true
            } else { return false }
        }
    }
    
    /// Cancels a download task through a specified url.
    public func cancel(with url: String) {
        _ = downloaderDict.first {
            if $0.key == url.cxd_sha2 { $0.value.cancel()
                return true
            } else { return false }
        }
    }
    
    /// Resumes the all download tasks.
    public func resumeAll() {
        downloaderDict.forEach { $0.value.resume() }
    }
    
    /// Pauses the all download tasks.
    public func pauseAll() {
        downloaderDict.forEach { $0.value.pause() }
    }
    
    /// Cancels the all download tasks.
    public func cancelAll() {
        downloaderDict.forEach { $0.value.cancel() }
    }
    
    /// Removes the target file through a specified url, the target directory and the custom filename.
    public func removeTargetFile(url: String, customDirectory: String? = nil, customFileName: String? = nil) {
        guard let anURL = URL.init(string: url) else {
            return
        }
        let filepath = CXDFileUtils.filePath(withURL: anURL, at: customDirectory, using: customFileName)
        CXDFileUtils.removeFile(atPath: filepath)
    }
    
    /// Cleans up the invalid download tasks.
    public func cleanUpInvalidTasks() {
        for key in downloaderDict.keys {
            guard let downloader = downloaderDict[key] else {
                continue
            }
            if downloader.state == .success || downloader.state == .failed || downloader.state == .cancelled {
                downloaderDict.removeValue(forKey: key)
            }
        }
    }
    
}
