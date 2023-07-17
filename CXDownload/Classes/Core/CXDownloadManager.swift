//
//  CXDownloadManager.swift
//  CXDownload
//
//  Created by chenxing on 2022/8/15.
//

import Foundation

/// The state for the download.
@objc public enum CXDownloadState: Int {
    // Represents the download state.
    case `default`, waiting, downloading, paused, cancelled, finish, error
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
    public var currentCount: Int!
    /// The max concurrent count for the download.
    public var maxConcurrentCount: Int!
    /// Whether to allow cellular network download.
    public var allowsCellularAccess: Bool!
    
    private var lock: NSLock!
    
    /// Sends the specified string("Reachable", "NotReachable", "ReachableViaWWAN" or "ReachableViaWiFi") by notification.object.
    private var networkReachabilityStatus: String = CXNetworkReachabilityStatus.reachable
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
        
        lock = NSLock()
        
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
        notiCenter.addObserver(self, selector: #selector(downloadMaxConcurrentCountOnChange(_:)), name: CXDownloadConfig.maxConcurrentCountChangeNotification, object: nil)
        notiCenter.addObserver(self, selector: #selector(downloadAllowsCellularAccessOnChange(_:)), name: CXDownloadConfig.allowsCellularAccessChangeNotification, object: nil)
        notiCenter.addObserver(self, selector: #selector(networkingReachabilityOnChange(_:)), name: CXDownloadConfig.networkingReachabilityDidChangeNotification, object: nil)
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
    @objc public func download(url: String,
                               progress: ((CXDownloadModel) -> Void)?,
                               success: ((CXDownloadModel) -> Void)?,
                               failure: ((CXDownloadModel) -> Void)?)
    {
        download(url: url, toDirectory: nil, fileName: nil, progress: progress, success: success, failure: failure)
    }
    
    /// Executes an asynchronous download with the url and some callback closures.
    @objc public func download(url: String,
                               toDirectory directory: String?,
                               fileName: String?,
                               progress: ((CXDownloadModel) -> Void)?,
                               success: ((CXDownloadModel) -> Void)?,
                               failure: ((CXDownloadModel) -> Void)?)
    {
        guard let aURL = URL(string: url) else {
            callbackError(failure)
            return
        }
        
        // It is forbidden to call the same task repeatedly within 1.0s.
        if let date = downloadDateDict[url], Date().timeIntervalSince(date) < 1.0 {
            return
        }
        downloadDateDict[url] = Date()
        
        let fname = fileName ?? CXDFileUtils.fileName(aURL)
        CXDLogger.log(message: "fileName=\(fname)", level: .info)
        
        var downloadModel = CXDownloadDatabaseManager.shared.getModel(by: url)
        if downloadModel == nil {
            downloadModel = CXDownloadModel()
            downloadModel!.url = url
            downloadModel!.fid = url.cxd_sha2
            downloadModel!.fileName = fname
            CXDownloadDatabaseManager.shared.insertModel(downloadModel!)
        }
        
        var taskProcessor = downloadTaskDict[url]
        if taskProcessor == nil {
            taskProcessor = createTaskProcessor(model: downloadModel!,
                                                toDirectory: directory,
                                                fileName: fname,
                                                progress: progress,
                                                success: success,
                                                failure: failure)
            downloadTaskDict[url] = taskProcessor
        }
        taskProcessor?.updateModelStateAndTime(downloadModel!)
        
        if currentCount < maxConcurrentCount && networkingAllowsDownloadTask() {
            downloadWithModel(downloadModel!)
        }
    }
    
    private func callbackError(_ failure: ((CXDownloadModel) -> Void)?) {
        CXDLogger.log(message: "The url is invalid.", level: .error)
        let model = CXDownloadModel()
        model.state = .error
        let stateInfo = CXDownloadStateInfo()
        stateInfo.code = -2000
        stateInfo.message = "The url is invalid"
        model.stateInfo = stateInfo
        runOnMainThread { failure?(model) }
    }
    
    private func createTaskProcessor(
        model: CXDownloadModel,
        toDirectory directory: String?,
        fileName: String?,
        progress: ((CXDownloadModel) -> Void)?,
        success: ((CXDownloadModel) -> Void)?,
        failure: ((CXDownloadModel) -> Void)?) -> CXDownloadTaskProcessor
    {
        let taskProcessor = CXDownloadTaskProcessor(model: model,
                                                    directory: directory,
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
            s.startDownloadingWaitingTask()
        }
        taskProcessor.urlSession = session
        return taskProcessor
    }
    
    @objc public func canCallback(url: String) -> Bool {
        guard let taskProcessor = downloadTaskDict[url] else {
            return false
        }
        return taskProcessor.canCallback()
    }
    
    /// Pauses a download task through a specified url.
    @objc public func pause(url: String) {
        update(toState: .paused, for: url)
    }
    
    /// Cancels a download task through a specified url.
    @objc public func cancel(url: String) {
        update(toState: .cancelled, for: url)
    }
    
    /// For pausing or cancelling.
    private func update(toState state: CXDownloadState, for url: String) {
        guard let taskProcessor = downloadTaskDict[url] else {
            return
        }
        if taskProcessor.state == .waiting || taskProcessor.state == .downloading {
            if state == .paused {
                taskProcessor.pauseTask()
                // Update the current downloaded count.
                updateCurrentCount(byAscending: false)
                startDownloadingWaitingTask()
            } else {
                taskProcessor.cancelTask()
            }
        }
    }
    
    /// Deletes the task, cache, target file through the specified url.
    @objc public func deleteTaskAndCache(url: String) {
        deleteTaskAndCache(url: url, atDirectory: nil, fileName: nil)
    }
    
    /// Deletes the task, cache, target file through the specified url, target directory and custom filename.
    @objc public func deleteTaskAndCache(url: String, atDirectory directory: String?, fileName: String?) {
        if let taskProcessor = downloadTaskDict[url] {
            taskProcessor.cancelTask()
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
        guard let key = model.url else { return }
        updateCurrentCount(byAscending: true)
        if let taskProcessor = downloadTaskDict[key] {
            taskProcessor.process()
        } else {
            let taskProcessor = createTaskProcessor(model: model, toDirectory: model.atDirectory, fileName: model.fileName, progress: nil, success: nil, failure: nil)
            taskProcessor.process()
            downloadTaskDict[key] = taskProcessor
        }
    }
    
    private func startDownloadingWaitingTask() {
        if currentCount < maxConcurrentCount && networkingAllowsDownloadTask() {
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
        guard count > 0 else {
            return
        }
        for i in 0..<count {
            let model = downloadingDataArray[i]
            CXDLogger.log(message: "[url=\(model.url ?? "")]: state=\(model.state.rawValue)", level: .info)
            guard let key = model.url else {
                continue
            }
            if let taskProcessor = downloadTaskDict[key] {
                taskProcessor.updateStateAsWaiting()
                updateCurrentCount(byAscending: false)
            } else {
                model.state = .waiting
                CXDownloadDatabaseManager.shared.updateModel(model, option: .state)
            }
        }
        if !all { startDownloadingWaitingTask() }
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
        CXDLogger.log(message: "The URL session did become invalid.", level: .info)
        if let err = error {
            CXDLogger.log(message: "error=\(err)", level: .info)
        }
        downloadTaskDict.forEach {
            $0.value.processSessionBecomeInvalid(with: error)
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
            guard let model = CXDownloadDatabaseManager.shared.getModel(by: url)
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
    
    @objc private func downloadMaxConcurrentCountOnChange(_ notification: Notification) {
        let numberObj = notification.object as? NSNumber
        
        maxConcurrentCount = numberObj?.intValue ?? 1
        CXDLogger.log(message: "maxConcurrentCount=\(maxConcurrentCount!)", level: .info)
        
        if currentCount < maxConcurrentCount {
            startDownloadingWaitingTask()
        } else if currentCount > maxConcurrentCount {
            pauseDownloadingTaskWithAll(false)
        }
    }
    
    @objc private func downloadAllowsCellularAccessOnChange(_ notification: Notification) {
        let numberObj = notification.object as? NSNumber
        
        allowsCellularAccess = numberObj?.boolValue ?? false
        CXDLogger.log(message: "allowsCellularAccess=\(allowsCellularAccess!)", level: .info)
        
        allowsCellularAccessOrNetworkingReachabilityDidChangeAction()
    }
    
    @objc private func networkingReachabilityOnChange(_ notification: Notification) {
        networkReachabilityStatus = (notification.object as? String) ?? ""
        CXDLogger.log(message: "networkReachabilityStatus=\(networkReachabilityStatus)", level: .info)
        
        allowsCellularAccessOrNetworkingReachabilityDidChangeAction()
    }
    
    /// Whether to allow cellular network download or network state change events.
    private func allowsCellularAccessOrNetworkingReachabilityDidChangeAction() {
        if networkReachabilityStatus == CXNetworkReachabilityStatus.notReachable {
            // No network, pause downloading task.
            pauseDownloadingTaskWithAll(true)
        } else {
            if networkingAllowsDownloadTask() {
                pauseDownloadingTaskWithAll(true)
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
        if networkReachabilityStatus == CXNetworkReachabilityStatus.notReachable || (networkReachabilityStatus == CXNetworkReachabilityStatus.reachableViaWWAN && !allowsCellularAccess) {
            return false
        }
        return true
    }
    
}
