//
//  CXDownloader.swift
//  CXDownload
//
//  Created by chenxing on 2022/8/15.
//

import Foundation

public class CXDownloader: NSObject {
    
    /// The state for the download.
    public enum DownloadState: UInt8 {
        case pause, downLoading, success, failed, cancelled
    }
    
    /// The error for the download.
    public enum DownloadError: Error {
        case error(code: Int, message: String)
    }
    
    public typealias ProgressClosure = (_ progress: Float) -> Void
    public typealias SuccessClosure = (_ filePath: String) -> Void
    public typealias FailureClosure = (_ error: DownloadError) -> Void
    public typealias FinishClosure = (_ url: String) -> Void
    public typealias StateChangeClosure = (_ state: DownloadState) -> Void
    
    private var progressClosure: ProgressClosure?
    private var successClosure: SuccessClosure?
    private var failureClosure: FailureClosure?
    private var finishClosure: FinishClosure?
    
    private(set) var urlString: String!
    /// The progress is 0..1.
    private(set) var progress: Float = 0
    
    private var resumedFileSize: Int64 = 0
    /// The destination file path.
    private var dstPath: String = ""
    /// The temp file path.
    private var tmpPath: String = ""
    
    private(set) var customDirectory: String?
    private(set) var customFileName: String?
    
    private var urlSession: URLSession?
    private var dataTask: URLSessionDataTask?
    private var outputStream: OutputStream?
    
    /// Creates an operation queue with the lazy load.
    private lazy var downloadQueue: OperationQueue = {
        let queue = OperationQueue.init()
        queue.maxConcurrentOperationCount = 1
        return queue
    }()
    
    public private(set) var state: DownloadState = .pause {
        didSet {
            stateChangeClosure?(state)
            if state == .success || state == .failed || state == .cancelled {
                finishTasksAndInvalidateSession()
                asyncExecute { self.finishClosure?(self.urlString) }
            }
        }
    }
    
    public var stateChangeClosure: StateChangeClosure?
    
    /// Initializes the url.
    init(url: String) {
        self.urlString = url
    }
    
    /// Initializes the url, custom directory, custom file name.
    convenience init(url: String, customDirectory: String?, customFileName: String?) {
        self.init(url: url)
        self.customDirectory = customDirectory
        self.customFileName = customFileName
    }
    
    /// Initializes the some required parameters.
    init(url: String, progess: ProgressClosure?, success: SuccessClosure?, failure: FailureClosure?, finish: FinishClosure?) {
        self.urlString = url
        self.progressClosure = progess
        self.successClosure = success
        self.failureClosure = failure
        self.finishClosure = finish
    }
    
    /// Initializes the url, custom directory, custom file name and some other required parameters.
    convenience init(url: String, customDirectory: String?, customFileName: String?, progess: ProgressClosure?, success: SuccessClosure?, failure: FailureClosure?, finish: FinishClosure?) {
        self.init(url: url, progess: progess, success: success, failure: failure, finish: finish)
        self.customDirectory = customDirectory
        self.customFileName = customFileName
    }
    
    /// Executes the download task with the some required parameters.
    public static func download(url: String, progess: @escaping ProgressClosure, success: @escaping SuccessClosure, failure: @escaping FailureClosure, finish: @escaping FinishClosure) -> CXDownloader {
        let downloader = CXDownloader.init(url: url, progess: progess, success: success, failure: failure, finish: finish)
        downloader.onDownload()
        return downloader
    }
    
    /// Executes the download task with the some required parameters.
    public static func download(url: String, customDirectory: String?, customFileName: String?, progess: @escaping ProgressClosure, success: @escaping SuccessClosure, failure: @escaping FailureClosure, finish: @escaping FinishClosure) -> CXDownloader {
        let downloader = CXDownloader.init(url: url, customDirectory: customDirectory, customFileName: customFileName, progess: progess, success: success, failure: failure, finish: finish)
        downloader.onDownload()
        return downloader
    }
    
    /// if call init(:) or init(:::), you need to call onCallback(::::).
    public func onCallback(progess: @escaping ProgressClosure, success: @escaping SuccessClosure, failure: @escaping FailureClosure, finish: @escaping FinishClosure) {
        self.progressClosure = progess
        self.successClosure = success
        self.failureClosure = failure
        self.finishClosure = finish
        self.onDownload()
    }
    
    /// Resumes the current data task.
    public func resume() {
        if dataTask != nil && state == .pause {
            dataTask?.resume()
            state = .downLoading
        }
    }
    
    /// Pauses the current data task.
    public func pause() {
        if dataTask != nil && state == .downLoading {
            dataTask?.suspend()
            state = .pause
        }
    }
    
    /// Cancels the current data task.
    public func cancel() {
        if dataTask != nil {
            dataTask?.cancel()
            state = .cancelled
        }
    }
    
    /// Schedules a block asynchronously for execution on main thread.
    public func runOnMainThread(block: @escaping () -> Void) {
        DispatchQueue.main.async(execute: block)
    }
    
    /// Schedules a block asynchronously for execution after delay.
    public func asyncExecute(afterDelay delay: TimeInterval = 0.2, block: @escaping () -> Void) {
        DispatchQueue.main.asyncAfter(deadline: .now() + delay, execute: block)
    }
    
    private func createURLSession() -> URLSession {
        let config = URLSessionConfiguration.default
        let urlSession = URLSession.init(configuration: config, delegate: self, delegateQueue: downloadQueue)
        self.urlSession = urlSession
        return urlSession
    }
    
    private func download(with url: URL, offset: Int64) {
        _ = createURLSession()
        var urlRequest = URLRequest.init(url: url, cachePolicy: .reloadIgnoringLocalCacheData)
        let requestRange = String(format: "bytes=%llu-", offset)
        urlRequest.setValue(requestRange, forHTTPHeaderField: "Range")
        self.dataTask = urlSession?.dataTask(with: urlRequest)
        self.resume()
    }
    
    private func onDownload() {
        guard let url = URL.init(string: urlString) else {
            CXLogger.log(message: "The url is empty.", level: .info)
            runOnMainThread {
                self.failureClosure?(DownloadError.error(code: -2000, message: "The url is empty."))
            }
            state = .failed
            return
        }
        CXLogger.log(message: "url: \(url)", level: .info)
        
        /// The current data task exists.
        if url == dataTask?.originalRequest?.url {
            CXLogger.log(message: "The current data task exists.", level: .info)
            /// If the download state is pause, resume the data task.
            if state == .pause {
                resume()
            }
            return
        }
        
        /// The dest file exists, this that indicates the download was completed.
        dstPath = CXFileUtils.filePath(withURL: url, at: customDirectory, using: customFileName)
        CXLogger.log(message: "DstPath: \(dstPath)", level: .info)
        if CXFileUtils.fileExists(atPath: dstPath) {
            progress = 1.0
            runOnMainThread {
                self.progressClosure?(self.progress)
                self.successClosure?(self.dstPath)
            }
            state = .success
            return
        }
        
        let fileName = CXFileUtils.fileName(url)
        tmpPath = CXFileUtils.tempDirectory().appending("\(fileName.cx_md5 ?? fileName)")
        CXLogger.log(message: "TmpPath: \(tmpPath)", level: .info)
        /// The temp file doesn't exist, the offset is 0.
        if !CXFileUtils.fileExists(atPath: tmpPath) {
            download(with: url, offset: 0)
            return
        }
        
        /// The file doesn't exist, you can get file size as the offset.
        resumedFileSize = CXFileUtils.fileSize(tmpPath)
        CXLogger.log(message: "Resumed FileSize: \(resumedFileSize)", level: .info)
        download(with: url, offset: resumedFileSize)
    }
    
    /// Removes the temp file.
    public func removeTempFile() {
        CXFileUtils.removeFile(atPath: tmpPath)
    }
    
    /// Invalidates the session, allowing any outstanding tasks to finish.
    public func finishTasksAndInvalidateSession() {
        urlSession?.finishTasksAndInvalidate()
    }
    
    /// Cancels all outstanding tasks and then invalidates the session.
    public func invalidateSessionAndCancelTasks() {
        urlSession?.invalidateAndCancel()
    }
    
    deinit {
        CXLogger.log(message: "\(type(of: self)): Deinited.", level: .info)
    }
    
}

extension CXDownloader: URLSessionDataDelegate {
    
    public func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive response: URLResponse, completionHandler: @escaping (URLSession.ResponseDisposition) -> Void) {
        guard let _response = response as? HTTPURLResponse else {
            CXLogger.log(message: "The http url response is empty.", level: .info)
            runOnMainThread {
                self.failureClosure?(DownloadError.error(code: -2001, message: "The http url response is empty."))
            }
            state = .failed
            completionHandler(.cancel)
            return
        }
        
        //CXLogger.log(message: "response.allHeaderFields: \(_response.allHeaderFields)", level: .info)
        /// The total size.
        var totalSize = Int64((_response.allHeaderFields["Content-Length"] as? String) ?? "") ?? 0
        let contentRange = (_response.allHeaderFields["Content-Range"] as? String) ?? ""
        if !contentRange.isEmpty {
            if let lastStr = contentRange.components(separatedBy: "/").last {
                totalSize = Int64(lastStr) ?? 0
            }
        }
        
        /// if the resumed file size is equal to the total size, executes it as follow.
        if totalSize > 0 && resumedFileSize == totalSize {
            CXFileUtils.moveFile(from: tmpPath, to: dstPath)
            completionHandler(.cancel)
            progress = 1.0
            runOnMainThread {
                self.progressClosure?(self.progress)
                self.successClosure?(self.dstPath)
            }
            state = .success
            return
        }
        
        /// if the resumed file size is greater than the total size, executes it as follow.
        if totalSize > 0 && resumedFileSize > totalSize {
            CXFileUtils.removeFile(atPath: tmpPath)
            completionHandler(.cancel)
            onDownload()
            return
        }
        
        /// No point break resume, code is 200, point break resume, code is 206
        if _response.statusCode == 200 || _response.statusCode == 206 {
            progress = Float(resumedFileSize) / Float(totalSize)
            runOnMainThread { self.progressClosure?(self.progress) }
            state = .downLoading
            outputStream = OutputStream.init(toFileAtPath: tmpPath, append: true)
            outputStream?.open()
            completionHandler(.allow)
            return
        }
        
        /// 403, no permission access, ....
        CXLogger.log(message: "An error occurs, the code is \(_response.statusCode).", level: .info)
        runOnMainThread {
            self.failureClosure?(DownloadError.error(code: _response.statusCode, message: "An error occurs."))
        }
        state = .failed
        completionHandler(.cancel)
    }
    
    public func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive data: Data) {
        let receivedBytes = dataTask.countOfBytesReceived + resumedFileSize
        let allBytes = dataTask.countOfBytesExpectedToReceive + resumedFileSize
        progress = Float(receivedBytes) / Float(allBytes)
        //CXLogger.log(message: "progress: \(progress)", level: .info)
        runOnMainThread { self.progressClosure?(self.progress) }
        /// Writes the received data to the temp file.
        let dataLength = data.count
        let _ = data.withUnsafeBytes { [weak self] in
            if let baseAddress = $0.bindMemory(to: UTF8.self).baseAddress {
                self?.outputStream?.write(baseAddress, maxLength: dataLength)
            }
        }
    }
    
    public func urlSession(_ session: URLSession, didBecomeInvalidWithError error: Error?) {
        guard let error = error as? NSError else {
            /// if error is nil, the url session become invalid.
            return
        }
        runOnMainThread {
            self.failureClosure?(DownloadError.error(code: error.code, message: error.localizedDescription))
        }
        state = .failed
    }
    
    public func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        outputStream?.close()
        /// If no error, handle the successful logic.
        guard let error = error as? NSError else {
            CXFileUtils.moveFile(from: tmpPath, to: dstPath)
            runOnMainThread { self.successClosure?(self.dstPath) }
            state = .success
            return
        }
        /// Cancels the data task.
        if error.code == NSURLErrorCancelled {
            CXLogger.log(message: "Code: \(error.code), message: \(error.localizedDescription)", level: .info)
        } else { /** No network, etc. */
            runOnMainThread {
                self.failureClosure?(DownloadError.error(code: error.code, message: error.localizedDescription))
            }
            state = .failed
        }
    }
    
}
