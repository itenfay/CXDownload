//
//  CXDownloadProcessor.swift
//  CXDownload
//
//  Created by chenxing on 2023/6/28.
//

import UIKit

protocol ICXDownloadProcessor {
    var urlSession: URLSession? {get set}
    var model: CXDownloadModel? {get set}
}

class CXDownloadProcessor {
    
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
    private var dataTask: URLSessionDataTask?
    
    weak var urlSession: URLSession?
    weak var model: CXDownloadModel?
    
    private var outputStream: OutputStream?
    
    private(set) var state: CXDownloadState = .waiting {
        didSet {
            stateChangeClosure?(state)
            if state == .finish || state == .error || state == .cancelled {
                finishTasksAndInvalidateSession()
                asyncExec { self.finishClosure?(self.urlString) }
            }
        }
    }
    
    var stateChangeClosure: StateChangeClosure?
    
    /// Initializes the url.
    init(url: String) {
        self.urlString = url
        self.state = .waiting
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
        self.state = .waiting
    }
    
    /// Initializes the url, custom directory, custom file name and some other required parameters.
    convenience init(url: String, customDirectory: String?, customFileName: String?, progess: ProgressClosure?, success: SuccessClosure?, failure: FailureClosure?, finish: FinishClosure?) {
        self.init(url: url, progess: progess, success: success, failure: failure, finish: finish)
        self.customDirectory = customDirectory
        self.customFileName = customFileName
    }
    
    /// Executes the download task with the some required parameters.
    static func download(url: String, progess: @escaping ProgressClosure, success: @escaping SuccessClosure, failure: @escaping FailureClosure, finish: @escaping FinishClosure) -> CXDownloadProcessor {
        let processor = CXDownloadProcessor.init(url: url, progess: progess, success: success, failure: failure, finish: finish)
        return processor
    }
    
    /// Executes the download task with the some required parameters.
    static func download(url: String, customDirectory: String?, customFileName: String?, progess: @escaping ProgressClosure, success: @escaping SuccessClosure, failure: @escaping FailureClosure, finish: @escaping FinishClosure) -> CXDownloadProcessor {
        let processor = CXDownloadProcessor(url: url, customDirectory: customDirectory, customFileName: customFileName, progess: progess, success: success, failure: failure, finish: finish)
        return processor
    }
    
    /// if call init(:) or init(:::), you need to call onCallback(::::).
    func onCallback(progess: @escaping ProgressClosure, success: @escaping SuccessClosure, failure: @escaping FailureClosure, finish: @escaping FinishClosure) {
        self.progressClosure = progess
        self.successClosure = success
        self.failureClosure = failure
        self.finishClosure = finish
    }
    
    /// Resumes the current data task.
    func resume() {
        if dataTask != nil && state == .paused {
            dataTask?.resume()
            state = .downloading
        }
    }
    
    /// Pauses the current data task.
    func pause() {
        if dataTask != nil && state == .downloading {
            dataTask?.suspend()
            state = .paused
        }
    }
    
    /// Cancels the current data task.
    func cancel() {
        if dataTask != nil {
            dataTask?.cancel()
            state = .cancelled
        }
    }
    
    /// Schedules a block asynchronously for execution on main thread.
    private func execOnMainThread(block: @escaping () -> Void) {
        DispatchQueue.main.async(execute: block)
    }
    
    /// Schedules a block asynchronously for execution after delay.
    private func asyncExec(afterDelay delay: TimeInterval = 0.2, block: @escaping () -> Void) {
        DispatchQueue.main.asyncAfter(deadline: .now() + delay, execute: block)
    }
    
    private func download(with url: URL, offset: Int64) {
        var urlRequest = URLRequest.init(url: url, cachePolicy: .reloadIgnoringLocalCacheData)
        let requestRange = String(format: "bytes=%llu-", offset)
        urlRequest.setValue(requestRange, forHTTPHeaderField: "Range")
        self.dataTask = urlSession?.dataTask(with: urlRequest)
        self.state = .paused
        self.resume()
    }
    
    func startDownloading() {
        guard let url = URL.init(string: urlString) else {
            CXDLogger.log(message: "The url is empty.", level: .info)
            execOnMainThread {
                self.failureClosure?(-2000, "The url is empty.")
            }
            state = .error
            return
        }
        CXDLogger.log(message: "url: \(url)", level: .info)
        
        // The current data task exists.
        if url == dataTask?.originalRequest?.url {
            CXDLogger.log(message: "The current data task exists.", level: .info)
            // If the download state is pause, resume the data task.
            if state == .paused {
                resume()
            }
            return
        }
        
        // The dest file exists, this that indicates the download was completed.
        dstPath = CXDFileUtils.filePath(withURL: url, at: customDirectory, using: customFileName)
        CXDLogger.log(message: "DstPath: \(dstPath)", level: .info)
        if CXDFileUtils.fileExists(atPath: dstPath) {
            progress = 1.0
            execOnMainThread {
                self.progressClosure?(self.progress)
                self.successClosure?(self.dstPath)
            }
            state = .finish
            return
        }
        
        let fileName = CXDFileUtils.fileName(url)
        tmpPath = CXDFileUtils.tempDirectory().appending("\(fileName.cxd_sha2 ?? fileName)")
        CXDLogger.log(message: "TmpPath: \(tmpPath)", level: .info)
        // The temp file doesn't exist, the offset is 0.
        if !CXDFileUtils.fileExists(atPath: tmpPath) {
            download(with: url, offset: 0)
            return
        }
        
        // The file doesn't exist, you can get file size as the offset.
        resumedFileSize = CXDFileUtils.fileSize(tmpPath)
        CXDLogger.log(message: "Resumed FileSize: \(resumedFileSize)", level: .info)
        download(with: url, offset: resumedFileSize)
    }
    
    /// Removes the temp file.
    func removeTempFile() {
        CXDFileUtils.removeFile(atPath: tmpPath)
    }
    
    /// Invalidates the session, allowing any outstanding tasks to finish.
    func finishTasksAndInvalidateSession() {
        //urlSession?.finishTasksAndInvalidate()
    }
    
    /// Cancels all outstanding tasks and then invalidates the session.
    func invalidateSessionAndCancelTasks() {
        //urlSession?.invalidateAndCancel()
    }
    
    func processSession(dataTask: URLSessionDataTask, didReceive response: URLResponse, completionHandler: @escaping (URLSession.ResponseDisposition) -> Void) {
        guard let resp = response as? HTTPURLResponse else {
            CXDLogger.log(message: "The http url response is empty.", level: .info)
            execOnMainThread {
                self.failureClosure?(-2001, "The http url response is empty.")
            }
            state = .error
            completionHandler(.cancel)
            return
        }
        
        //CXDLogger.log(message: "response.allHeaderFields: \(resp.allHeaderFields)", level: .info)
        // The total size.
        var totalSize = Int64((resp.allHeaderFields["Content-Length"] as? String) ?? "") ?? 0
        let contentRange = (resp.allHeaderFields["Content-Range"] as? String) ?? ""
        if !contentRange.isEmpty {
            if let lastStr = contentRange.components(separatedBy: "/").last {
                totalSize = Int64(lastStr) ?? 0
            }
        }
        
        // if the resumed file size is equal to the total size, executes it as follow.
        if totalSize > 0 && resumedFileSize == totalSize {
            CXDFileUtils.moveFile(from: tmpPath, to: dstPath)
            completionHandler(.cancel)
            progress = 1.0
            execOnMainThread {
                self.progressClosure?(self.progress)
                self.successClosure?(self.dstPath)
            }
            state = .finish
            return
        }
        
        // if the resumed file size is greater than the total size, executes it as follow.
        if totalSize > 0 && resumedFileSize > totalSize {
            CXDFileUtils.removeFile(atPath: tmpPath)
            completionHandler(.cancel)
            startDownloading()
            return
        }
        
        // No point break resume, code is 200, point break resume, code is 206
        if resp.statusCode == 200 || resp.statusCode == 206 {
            progress = Float(resumedFileSize) / Float(totalSize)
            execOnMainThread { self.progressClosure?(self.progress) }
            state = .downloading
            outputStream = OutputStream.init(toFileAtPath: tmpPath, append: true)
            outputStream?.open()
            completionHandler(.allow)
            return
        }
        
        // 403, no permission access, ....
        CXDLogger.log(message: "An error occurs, the code is \(resp.statusCode).", level: .info)
        execOnMainThread {
            self.failureClosure?(resp.statusCode, "An error occurs.")
        }
        state = .error
        completionHandler(.cancel)
    }
    
    func processSession(dataTask: URLSessionDataTask, didReceive data: Data) {
        let receivedBytes = dataTask.countOfBytesReceived + resumedFileSize
        let allBytes = dataTask.countOfBytesExpectedToReceive + resumedFileSize
        progress = Float(receivedBytes) / Float(allBytes)
        //CXDLogger.log(message: "progress: \(progress)", level: .info)
        execOnMainThread { self.progressClosure?(self.progress) }
        // Writes the received data to the temp file.
        let dataLength = data.count
        let _ = data.withUnsafeBytes { [weak self] in
            if let baseAddress = $0.bindMemory(to: UTF8.self).baseAddress {
                self?.outputStream?.write(baseAddress, maxLength: dataLength)
            }
        }
    }
    
    func processSessionError(_ error: Error?) {
        guard let error = error as? NSError else {
            // if error is nil, the url session become invalid.
            return
        }
        execOnMainThread {
            self.failureClosure?(error.code, error.localizedDescription)
        }
        state = .error
    }
    
    func processSessionTaskDidComplete(with error: Error?) {
        outputStream?.close()
        // If no error, handle the successful logic.
        guard let error = error as? NSError else {
            CXDFileUtils.moveFile(from: tmpPath, to: dstPath)
            execOnMainThread { self.successClosure?(self.dstPath) }
            state = .finish
            return
        }
        // Cancels the data task.
        if error.code == NSURLErrorCancelled {
            CXDLogger.log(message: "Code: \(error.code), message: \(error.localizedDescription)", level: .info)
        } else { /** No network, etc. */
            execOnMainThread {
                self.failureClosure?(error.code, error.localizedDescription)
            }
            state = .error
        }
    }
    
    deinit {
        CXDLogger.log(message: "\(type(of: self)): Deinited.", level: .info)
    }
    
}
