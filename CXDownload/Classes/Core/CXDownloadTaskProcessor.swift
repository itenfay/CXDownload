//
//  CXDownloadProcessor.swift
//  CXDownload
//
//  Created by chenxing on 2023/6/28.
//

import UIKit

protocol ICXDownloadProcessor {
    var urlSession: URLSession? { get set }
}

class CXDownloadProcessor: ICXDownloadProcessor {
    
    private var progressCallback: CXDownloadCallback?
    private var successCallback: CXDownloadCallback?
    private var failureCallback: CXDownloadCallback?
    private var finishCallback: CXDownloadCallback?
    
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
    
    private let model: CXDownloadModel
    private var outputStream: OutputStream?
    private var dataTask: URLSessionDataTask?
    weak var urlSession: URLSession?
    
    private(set) var state: CXDownloadState = .waiting
    
    /// Initializes the some required parameters.
    init(
        model: CXDownloadModel,
        progess: CXDownloadCallback?,
        success: CXDownloadCallback?,
        failure: CXDownloadCallback?,
        finish: CXDownloadCallback?)
    {
        self.model = model
        self.urlString = model.url
        self.progressCallback = progess
        self.successCallback = success
        self.failureCallback = failure
        self.finishCallback = finish
        self.state = .waiting
    }
    
    /// Initializes the model, custom directory, custom file name and some other required parameters.
    convenience init(
        model: CXDownloadModel,
        customDirectory: String?,
        customFileName: String?,
        progess: CXDownloadCallback?,
        success: CXDownloadCallback?,
        failure: CXDownloadCallback?,
        finish: CXDownloadCallback?)
    {
        self.init(model: model, progess: progess, success: success, failure: failure, finish: finish)
        self.customDirectory = customDirectory
        self.customFileName = customFileName
    }
    
    /// Resumes the current data task.
    func resumeTask() {
        if dataTask != nil && state == .paused {
            dataTask?.resume()
            state = .downloading
        }
    }
    
    /// Pauses the current data task.
    func pauseTask() {
        if dataTask != nil && state == .downloading {
            dataTask?.suspend()
            state = .paused
        }
    }
    
    /// Cancels the current data task.
    func cancelTask() {
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
    
    func process() {
        guard let url = URL.init(string: urlString) else {
            CXDLogger.log(message: "The url is empty.", level: .info)
            execOnMainThread {
                self.failureCallback?(-2000, "The url is empty.")
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
                resumeTask()
            }
            return
        }
        
        // The dest file exists, this that indicates the download was completed.
        dstPath = CXDFileUtils.filePath(withURL: url, at: customDirectory, using: customFileName)
        CXDLogger.log(message: "DstPath: \(dstPath)", level: .info)
        if CXDFileUtils.fileExists(atPath: dstPath) {
            progress = 1.0
            execOnMainThread {
                //self.progressCallback?(self.progress)
                //self.successCallback?(self.dstPath)
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
    
    private func download(with url: URL, offset: Int64) {
        var urlRequest = URLRequest.init(url: url, cachePolicy: .reloadIgnoringLocalCacheData)
        let requestRange = String(format: "bytes=%llu-", offset)
        urlRequest.setValue(requestRange, forHTTPHeaderField: "Range")
        self.dataTask = urlSession?.dataTask(with: urlRequest)
        self.state = .paused
        self.resumeTask()
    }
    
    /// Removes the temp file.
    func removeTempFile() {
        CXDFileUtils.removeFile(atPath: tmpPath)
    }
    
    /// Invalidates the session, allowing any outstanding tasks to finish.
    //func finishTasksAndInvalidateSession() {
    //    urlSession?.finishTasksAndInvalidate()
    //}
    
    /// Cancels all outstanding tasks and then invalidates the session.
    //func invalidateSessionAndCancelTasks() {
    //    urlSession?.invalidateAndCancel()
    //}
    
    func processSession(dataTask: URLSessionDataTask, didReceive response: URLResponse, completionHandler: @escaping (URLSession.ResponseDisposition) -> Void) {
        guard let resp = response as? HTTPURLResponse else {
            CXDLogger.log(message: "The http url response is empty.", level: .info)
            execOnMainThread {
                self.failureCallback?(-2001, "The http url response is empty.")
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
                //self.progressCallback?(self.progress)
                //self.successCallback?(self.dstPath)
            }
            state = .finish
            return
        }
        
        // if the resumed file size is greater than the total size, executes it as follow.
        if totalSize > 0 && resumedFileSize > totalSize {
            CXDFileUtils.removeFile(atPath: tmpPath)
            completionHandler(.cancel)
            process()
            return
        }
        
        // No point break resume, code is 200, point break resume, code is 206
        if resp.statusCode == 200 || resp.statusCode == 206 {
            progress = Float(resumedFileSize) / Float(totalSize)
            //execOnMainThread { self.progressCallback?(self.progress) }
            state = .downloading
            outputStream = OutputStream.init(toFileAtPath: tmpPath, append: true)
            outputStream?.open()
            completionHandler(.allow)
            return
        }
        
        // 403, no permission access, ....
        CXDLogger.log(message: "An error occurs, the code is \(resp.statusCode).", level: .info)
        execOnMainThread {
            self.failureCallback?(resp.statusCode, "An error occurs.")
        }
        state = .error
        completionHandler(.cancel)
    }
    
    func processSession(dataTask: URLSessionDataTask, didReceive data: Data) {
        let receivedBytes = dataTask.countOfBytesReceived + resumedFileSize
        let allBytes = dataTask.countOfBytesExpectedToReceive + resumedFileSize
        progress = Float(receivedBytes) / Float(allBytes)
        //CXDLogger.log(message: "progress: \(progress)", level: .info)
        //execOnMainThread { self.progressCallback?(self.progress) }
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
            self.failureCallback?(error.code, error.localizedDescription)
        }
        state = .error
    }
    
    func processSessionTaskDidComplete(with error: Error?) {
        outputStream?.close()
        // If no error, handle the successful logic.
        guard let error = error as? NSError else {
            CXDFileUtils.moveFile(from: tmpPath, to: dstPath)
            model.localPath = dstPath
            execOnMainThread { self.successCallback?(self.model) }
            state = .finish
            return
        }
        // Cancels the data task.
        if error.code == NSURLErrorCancelled {
            CXDLogger.log(message: "Code: \(error.code), message: \(error.localizedDescription)", level: .info)
        } else {
            // No network, etc.
            execOnMainThread {
                self.failureCallback?(error.code, error.localizedDescription)
            }
            state = .error
        }
    }
    
    deinit {
        CXDLogger.log(message: "\(type(of: self)): Deinited.", level: .info)
    }
    
}
