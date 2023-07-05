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
    
    private lazy var lock = NSLock()
    
    /// Sends the specified string("Reachable", "NotReachable", "ReachableViaWWAN" or "ReachableViaWiFi") by notification.object.
    private var networkReachabilityStatus: String = "Reachable"
    private var queue: OperationQueue!
    private var session: URLSession!
    
    private var cellularAccessNotAllowedPromptHandler: (() -> Void)?
    private var didFinishEventsForBackgroundURLSessionHandler: (() -> Void)?
    
    private func setup() {
        // Creates a database and a table.
        _ = CXDownloadDatabaseManager.shared
        
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
        // Allows cellular network download, the default is true, which is turned on here. We added a variable to control the user's switching choice.
        configuration.allowsCellularAccess = true
        
        // Create `URLSession`, configure information, proxy, proxy thread.
        session = URLSession(configuration: configuration, delegate: self, delegateQueue: queue)
        
        let notiCenter = NotificationCenter.default
        notiCenter.addObserver(self, selector: #selector(onDownloadMaxConcurrentCountChange(_:)), name: CXDownloadConfig.maxConcurrentCountChangeNotification, object: nil)
        notiCenter.addObserver(self, selector: #selector(onDownloadAllowsCellularAccessChange(_:)), name: CXDownloadConfig.allowsCellularAccessChangeNotification, object: nil)
        notiCenter.addObserver(self, selector: #selector(onNetworkingReachabilityChange(_:)), name: CXDownloadConfig.networkingReachabilityDidChangeNotification, object: nil)
    }
    
    /// Displays a prompt that cellular networks are not allowed.
    @objc public func showPromptForCellularAccessNotAllowed(handler: (() -> Void)?) {
        cellularAccessNotAllowedPromptHandler = handler
    }
    
    /// Sets a block to be executed once all messages enqueued for a session have been delivered.
    @objc public func setDidFinishEventsForBackgroundURLSession(completionHandler: (() -> Void)?) {
        didFinishEventsForBackgroundURLSessionHandler = completionHandler
    }
    
    /// Executes an asynchronous download with the url and some callback closures.
    @objc public func download(
        url: String,
        progress: @escaping (CXDownloadModel) -> Void,
        success: @escaping (CXDownloadModel) -> Void,
        failure: @escaping (CXDownloadModel) -> Void)
    {
        download(url: url, toDirectory: nil, fileName: nil, progress: progress, success: success, failure: failure)
    }
    
    /// Executes an asynchronous download with the url and some callback closures.
    @objc public func download(
        url: String,
        toDirectory directory: String?,
        fileName: String?,
        progress: @escaping (CXDownloadModel) -> Void,
        success: @escaping (CXDownloadModel) -> Void,
        failure: @escaping (CXDownloadModel) -> Void)
    {
        guard let aURL = URL(string: url) else {
            CXDLogger.log(message: "The url is invalid.", level: .error)
            let model = CXDownloadModel()
            model.state = .error
            let stateInfo = CXDownloadStateInfo()
            stateInfo.code = -2000
            stateInfo.message = "The url is invalid"
            model.stateInfo = stateInfo
            runOnMainThread {
                failure(model)
            }
            return
        }
        
        // It is forbidden to call the same task repeatedly within 1.0s.
        if let date = downloadDateDict[url], Date().timeIntervalSince(date) < 1.0 {
            return
        }
        downloadDateDict[url] = Date()
        
        var downloadModel = CXDownloadDatabaseManager.shared.getModel(by: url)
        if downloadModel == nil {
            downloadModel = CXDownloadModel()
            downloadModel?.url = url
            downloadModel?.fid = url.cxd_sha2
            downloadModel?.fileName = CXDFileUtils.lastPathComponent(aURL)
            CXDownloadDatabaseManager.shared.insertModel(downloadModel!)
        }
        
        var taskProcessor = downloadTaskDict[url]
        if taskProcessor == nil {
            taskProcessor = CXDownloadTaskProcessor(model: downloadModel!,
                                                    atDirectory: directory,
                                                    fileName: fileName,
                                                    progess: progress,
                                                    success: success,
                                                    failure: failure) { [weak self] model in
                guard let s = self else { return }
                guard let key = model.url else {
                    s.startDownloadingWaitingTask()
                    return
                }
                s.updateCurrentCount(byAscending: false)
                s.downloadTaskDict.removeValue(forKey: key)
                s.downloadDateDict.removeValue(forKey: key)
                // Cancels the task actively or Occurs an error.
                // Comment: Next call to reset state because of removing download task.
                //if model.state == .cancelled || model.state == .error {
                //    CXDownloadDatabaseManager.shared.deleteModel(by: key)
                //}
                s.startDownloadingWaitingTask()
            }
            taskProcessor?.updateStateAsWaiting()
            taskProcessor?.urlSession = session
            downloadTaskDict[url] = taskProcessor
        }
        
        // Download (given a waiting time, ensure that currentCount is updated)
        //Thread.sleep(forTimeInterval: 0.1)
        if (currentCount < maxConcurrentCount) && networkingAllowsDownloadTask() {
            downloadWithModel(downloadModel!)
        }
    }
    
    /// Resumes a download task through a specified url.
    @objc public func resumeWithURLString(_ url: String) {
        if let taskProcessor = downloadTaskDict[url],
           taskProcessor.state == .paused {
            if currentCount < maxConcurrentCount {
                taskProcessor.resumeTask()
            }
        }
    }
    
    /// Pauses a download task through a specified url.
    @objc public func pauseWithURLString(_ url: String) {
        if let taskProcessor = downloadTaskDict[url] {
            if taskProcessor.pauseTask() {
                updateCurrentCount(byAscending: false)
                startDownloadingWaitingTask()
            }
        }
    }
    
    /// Cancels a download task through a specified url.
    @objc public func cancelWithURLString(_ url: String) {
        if let taskProcessor = downloadTaskDict[url],
           taskProcessor.state == .downloading {
            taskProcessor.cancelTask()
        }
    }
    
    /// Deletes the task, cache, target file through the specified url.
    @objc public func deleteTaskAndCache(url: String) {
        deleteTaskAndCache(url: url, atDirectory: nil, fileName: nil)
    }
    
    /// Deletes the task, cache, target file through the specified url, target directory and custom filename.
    @objc public func deleteTaskAndCache(url: String, atDirectory directory: String?, fileName: String?) {
        if let model = CXDownloadDatabaseManager.shared.getModel(by: url) {
            cancelTaskWithModel(model, isDeleted: true)
        }
        DispatchQueue.global().async {
            if let aURL = URL.init(string: url) {
                let filepath = CXDFileUtils.filePath(withURL: aURL, atDirectory: directory, fileName: fileName)
                CXDFileUtils.removeFile(atPath: filepath)
            }
            CXDownloadDatabaseManager.shared.deleteModel(by: url)
        }
    }
    
    /// Invalidates the session, allowing any outstanding tasks to finish.
    //@objc public func finishTasksAndInvalidateSession() {
    //    urlSession?.finishTasksAndInvalidate()
    //}
    
    /// Cancels all outstanding tasks and then invalidates the session.
    //@objc public func invalidateSessionAndCancelTasks() {
    //    urlSession?.invalidateAndCancel()
    //}
    
    private func downloadWithModel(_ model: CXDownloadModel) {
        if let url = model.url, let taskProcessor = downloadTaskDict[url] {
            if taskProcessor.state == .waiting ||
                taskProcessor.state == .paused ||
                taskProcessor.state == .cancelled ||
                taskProcessor.state == .error {
                updateCurrentCount(byAscending: true)
                taskProcessor.process()
            }
        }
    }
    
    private func startDownloadingWaitingTask() {
        if (currentCount < maxConcurrentCount) && networkingAllowsDownloadTask() {
            guard let model = CXDownloadDatabaseManager.shared.getWaitingModel() else {
                return
            }
            downloadWithModel(model)
            
            // Recursively, start the next waiting task.
            startDownloadingWaitingTask()
        }
    }
    
    private func pauseDownloadingTaskWithAll(_ all: Bool) {
        let downloadingDataArray = CXDownloadDatabaseManager.shared.getAllDownloadingData()
        let count = all ? downloadingDataArray.count : downloadingDataArray.count - maxConcurrentCount
        for i in 0..<count {
            // Cancel task.
            let model = downloadingDataArray[i]
            cancelTaskWithModel(model, isDeleted: false)
            
            // Update state as waiting.
            model.state = .waiting
            CXDownloadDatabaseManager.shared.updateModel(model, option: .state)
        }
    }
    
    private func cancelTaskWithModel(_ model: CXDownloadModel, isDeleted: Bool) {
        if model.state == .downloading, let key = model.url {
            if let taskProcessor = downloadTaskDict[key] {
                taskProcessor.autoCancel()
                
                // Updates the downloaded count currently.
                updateCurrentCount(byAscending: false)
                
                startDownloadingWaitingTask()
            }
            
            if isDeleted {
                downloadTaskDict.removeValue(forKey: key)
                downloadDateDict.removeValue(forKey: key)
            }
        }
    }
    
    private func updateCurrentCount(byAscending ascending: Bool) {
        lock.lock()
        if ascending {
            currentCount += 1
        } else {
            if currentCount > 0 {
                currentCount -= 1
            }
        }
        lock.unlock()
    }
    
    deinit {
        session.invalidateAndCancel()
        NotificationCenter.default.removeObserver(self)
    }
    
}

//MARK: - URLSessionDataDelegate

extension CXDownloadManager: URLSessionDataDelegate {
    
    /// The application is in the background, and it is called after all download tasks are completed and the URLSession protocol is called.
    public func urlSessionDidFinishEvents(forBackgroundURLSession session: URLSession) {
        // Execute the block, the system generates a snapshot in the background, and releases the assertion that prevents the application from being suspended.
        didFinishEventsForBackgroundURLSessionHandler?()
    }
    
    public func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive response: URLResponse, completionHandler: @escaping (URLSession.ResponseDisposition) -> Void) {
        guard let url = dataTask.taskDescription else {
            completionHandler(.cancel)
            return
        }
        let taskProcessor = downloadTaskDict[url]
        taskProcessor?.processSession(dataTask: dataTask, didReceive: response, completionHandler: completionHandler)
    }
    
    public func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive data: Data) {
        guard let url = dataTask.taskDescription else {
            return
        }
        let taskProcessor = downloadTaskDict[url]
        taskProcessor?.processSession(dataTask: dataTask, didReceive: data)
    }
    
    public func urlSession(_ session: URLSession, didBecomeInvalidWithError error: Error?) {
        if let err = error {
            CXDLogger.log(message: "error=\(err)", level: .error)
        } else {
            CXDLogger.log(message: "The URL session did become invalid.", level: .info)
        }
    }
    
    public func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        guard let url = task.taskDescription else {
            return
        }
        // Process killed when downloading, callback error when restarting.
        if let err = error as? NSError,
           let reason = err.userInfo[NSURLErrorBackgroundTaskCancelledReasonKey] {
            CXDLogger.log(message: "Reason=\(reason)", level: .info)
            guard let url = task.taskDescription,
                  let model = CXDownloadDatabaseManager.shared.getModel(by: url)
            else {
                return
            }
            model.state = .waiting
            CXDownloadDatabaseManager.shared.updateModel(model, option: .state)
            return
        }
        let taskProcessor = downloadTaskDict[url]
        taskProcessor?.processSession(task: task, didCompleteWithError: error)
    }
    
}

//MARK: - Notification

extension CXDownloadManager {
    
    @objc private func onDownloadMaxConcurrentCountChange(_ notification: Notification) {
        maxConcurrentCount = (notification.object as? Int) ?? 1
        if currentCount < maxConcurrentCount {
            startDownloadingWaitingTask()
        } else if currentCount > maxConcurrentCount {
            pauseDownloadingTaskWithAll(false)
        }
    }
    
    @objc private func onDownloadAllowsCellularAccessChange(_ notification: Notification) {
        allowsCellularAccess = (notification.object as? Bool) ?? false
        allowsCellularAccessOrNetworkingReachabilityDidChangeAction()
    }
    
    @objc private func onNetworkingReachabilityChange(_ notification: Notification) {
        networkReachabilityStatus = (notification.object as? String) ?? ""
        allowsCellularAccessOrNetworkingReachabilityDidChangeAction()
    }
    
    /// Whether to allow cellular network download or network state change events.
    private func allowsCellularAccessOrNetworkingReachabilityDidChangeAction() {
        if networkReachabilityStatus == "NotReachable" {
            // No network, pause downloading task.
            pauseDownloadingTaskWithAll(true)
        } else {
            if networkingAllowsDownloadTask() {
                // Start the waiting task.
                startDownloadingWaitingTask()
            } else {
                // Maybe show prompt in here.
                let model = CXDownloadDatabaseManager.shared.getLastDownloadingModel()
                if model != nil {
                    cellularAccessNotAllowedPromptHandler?()
                }
                // At present, it is a cellular network, and downloading is not allowed. Pausing the all downloading task.
                pauseDownloadingTaskWithAll(true)
            }
        }
    }
    
    private func networkingAllowsDownloadTask() -> Bool {
        if networkReachabilityStatus == "NotReachable" || (networkReachabilityStatus == "ReachableViaWWAN" && !allowsCellularAccess) {
            return false
        }
        return true
    }
    
}
