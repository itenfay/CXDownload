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

/// Schedules a block asynchronously for execution on main thread.
internal func runOnMainThread(block: @escaping () -> Void) {
    DispatchQueue.main.async(execute: block)
}

/// Schedules a block asynchronously for execution after delay.
internal func asyncExec(afterDelay delay: TimeInterval = 0.2, block: @escaping () -> Void) {
    DispatchQueue.main.asyncAfter(deadline: .now() + delay, execute: block)
}

typealias CXDownloadCallback = (_ model: CXDownloadModel) -> Void

public class CXDownloadManager: NSObject {
    
    /// Returns a singleton instance.
    @objc public static let shared = CXDownloadManager()
    
    /// Privatizes the constructor.
    private override init() {
        super.init()
        self.setup()
    }
    
    /// The dictionary stores the download processor.
    private var downloadTaskDict: [String : CXDownloadTaskProcessor] = [:]
    /// The dictionary stores the download date.
    private var downloadDateDict: [String : Date] = [:]
    
    /// The count of downloads currently in progress.
    public var currentCount: Int = 0
    /// The max concurrent count for the download.
    public var maxConcurrentCount: Int = 1
    /// Whether to allow cellular network download.
    public var allowsCellularAccess: Bool = false
    
    /// Sends the specified string("NotReachable", "ReachableViaWWAN" or "ReachableViaWiFi") by notification.object.
    private var networkReachabilityStatus: String = ""
    private var queue: OperationQueue!
    private var session: URLSession!
    
    private func setup() {
        currentCount = 0
        let ud = UserDefaults.standard
        let tmaxConcurrentCount = ud.integer(forKey: CXDownloadConfig.maxConcurrentCountKey)
        maxConcurrentCount = tmaxConcurrentCount > 0 ? tmaxConcurrentCount : 1
        allowsCellularAccess = ud.bool(forKey: CXDownloadConfig.allowsCellularAccessKey)
        
        // Single-threaded proxy queue.
        queue = OperationQueue()
        queue.maxConcurrentOperationCount = 1
        
        // Defines the background session identifier.
        let configuration = URLSessionConfiguration.background(withIdentifier: "CXDownloadBackgroundSessionIdentifier")
        // Allows cellular network download, the default is YES, which is turned on here. We added a variable to control the user's switching choice.
        configuration.allowsCellularAccess = true
        
        // Create `URLSession`, configure information, proxy, proxy thread.
        session = URLSession(configuration: configuration, delegate: self, delegateQueue: queue)
        
        let notiCenter = NotificationCenter.default
        notiCenter.addObserver(self, selector: #selector(onDownloadMaxConcurrentCountChange(_:)), name: CXDownloadConfig.maxConcurrentCountChangeNotification, object: nil)
        notiCenter.addObserver(self, selector: #selector(onDownloadAllowsCellularAccessChange(_:)), name: CXDownloadConfig.allowsCellularAccessChangeNotification, object: nil)
        notiCenter.addObserver(self, selector: #selector(networkingReachabilityDidChange(_:)), name: CXDownloadConfig.networkingReachabilityDidChangeNotification, object: nil)
    }
    
    /// Executes an asynchronous download with the url and some callback closures.
    public func download(url: String,
                         progress: @escaping (CXDownloadModel) -> Void,
                         success: @escaping (CXDownloadModel) -> Void,
                         failure: @escaping (CXDownloadModel) -> Void)
    {
        // It is forbidden to call the same task repeatedly within 1.0s
        if let date = downloadDateDict[url], Date().timeIntervalSince(date) < 1.0 {
            return
        }
        downloadDateDict[url] = Date()
        var downloadModel = CXDownloadDatabaseManager.shared.getModel(by: url)
        if downloadModel == nil {
            downloadModel = CXDownloadModel()
            downloadModel?.url = url
            downloadModel?.fid = url.cxd_sha2
            CXDownloadDatabaseManager.shared.insertModel(downloadModel!)
        }
    }
    
    /// Executes an asynchronous download with the url and some callback closures.
    public func download(url: String,
                         customDirectory: String?,
                         customFileName: String?,
                         progress: @escaping (CXDownloadModel) -> Void,
                         success: @escaping (CXDownloadModel) -> Void,
                         failure: @escaping (CXDownloadModel) -> Void)
    {
        
    }
    
    /// Resumes a download task through a specified url.
    public func resume(with url: String) {
        _ = downloadTaskDict.first {
            if $0.key == url.cxd_sha2 { $0.value.resumeTask()
                return true
            } else { return false }
        }
    }
    
    /// Pauses a download task through a specified url.
    public func pause(with url: String) {
        _ = downloadTaskDict.first {
            if $0.key == url.cxd_sha2 { $0.value.pauseTask()
                return true
            } else { return false }
        }
    }
    
    /// Cancels a download task through a specified url.
    public func cancel(with url: String) {
        _ = downloadTaskDict.first {
            if $0.key == url.cxd_sha2 { $0.value.cancelTask()
                return true
            } else { return false }
        }
    }
    
    /// Resumes the all download tasks.
    public func resumeAll() {
        downloadTaskDict.forEach { $0.value.resumeTask() }
    }
    
    /// Pauses the all download tasks.
    public func pauseAll() {
        downloadTaskDict.forEach { $0.value.pauseTask() }
    }
    
    /// Cancels the all download tasks.
    public func cancelAll() {
        downloadTaskDict.forEach { $0.value.cancelTask() }
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
        for key in downloadTaskDict.keys {
            guard let processor = downloadTaskDict[key] else {
                continue
            }
            if processor.state == .finish || processor.state == .error || processor.state == .cancelled {
                downloadTaskDict.removeValue(forKey: key)
            }
        }
    }
    
    deinit {
        session.invalidateAndCancel()
        NotificationCenter.default.removeObserver(self)
    }
    
}

//MARK: - URLSessionDataDelegate

extension CXDownloadManager: URLSessionDataDelegate {
    
    public func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive response: URLResponse, completionHandler: @escaping (URLSession.ResponseDisposition) -> Void) {
        
    }
    
    public func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive data: Data) {
        
    }
    
    public func urlSession(_ session: URLSession, didBecomeInvalidWithError error: Error?) {
        
    }
    
    public func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        
    }
    
}

//MARK: - Notification

extension CXDownloadManager {
    
    @objc private func onDownloadMaxConcurrentCountChange(_ notification: Notification) {
        
    }
    
    @objc private func onDownloadAllowsCellularAccessChange(_ notification: Notification) {
        
    }
    
    @objc private func networkingReachabilityDidChange(_ notification: Notification) {
        networkReachabilityStatus = (notification.object as? String) ?? ""
    }
    
    private func networkingAllowsDownloadTask() -> Bool {
        if networkReachabilityStatus == "" || networkReachabilityStatus == "NotReachable" || (networkReachabilityStatus == "ReachableViaWWAN" && !allowsCellularAccess) {
            return false
        }
        return true
    }
    
}
