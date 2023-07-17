//
//  CXDownloadTaskProcessor.swift
//  CXDownload
//
//  Created by chenxing on 2023/6/28.
//

import Foundation

protocol DownloadTaskProcessor {
    var urlSession: URLSession? { get set }
    var url: String? { get }
    var state: CXDownloadState { get set }
}

class CXDownloadTaskProcessor: DownloadTaskProcessor {
    
    private var progressCallback: CXDownloadCallback?
    private var successCallback: CXDownloadCallback?
    private var failureCallback: CXDownloadCallback?
    private var finishCallback: CXDownloadCallback?
    
    private let notificationCenter = NotificationCenter.default
    
    private var resumedFileSize: Int64 = 0
    /// The destination file path.
    private var dstPath: String = ""
    /// The temp file path.
    private var tmpPath: String = ""
    
    private(set) var directory: String?
    private(set) var fileName: String?
    
    private var model: CXDownloadModel
    private var outputStream: OutputStream?
    private var dataTask: URLSessionDataTask?
    
    weak var urlSession: URLSession?
    
    var url: String? { model.url }
    
    var state: CXDownloadState {
        get { model.state }
        set {
            model.state = newValue
        }
    }
    
    /// Initializes the some required parameters.
    init(model: CXDownloadModel,
         progess: CXDownloadCallback?,
         success: CXDownloadCallback?,
         failure: CXDownloadCallback?,
         finish: CXDownloadCallback?)
    {
        self.model = model
        self.progressCallback = progess
        self.successCallback = success
        self.failureCallback = failure
        self.finishCallback = finish
    }
    
    /// Initializes the model, target directory, custom file name and some other required parameters.
    convenience init(model: CXDownloadModel,
                     directory: String?,
                     fileName: String?,
                     progess: CXDownloadCallback?,
                     success: CXDownloadCallback?,
                     failure: CXDownloadCallback?,
                     finish: CXDownloadCallback?)
    {
        self.init(model: model, progess: progess, success: success, failure: failure, finish: finish)
        self.directory = directory
        self.fileName = fileName
    }
    
    func updateModelStateAndTime(_ downloadModel: CXDownloadModel) {
        downloadModel.state = .waiting
        downloadModel.lastStateTime = Int64(CXDToolbox.getTimestampWithDate(Date()))
        model = downloadModel
        runOnMainThread { self.progressCallback?(self.model) }
        CXDownloadDatabaseManager.shared.updateModel(model, option: [.state, .lastStateTime])
    }
    
    func canCallback() -> Bool {
        return progressCallback != nil && failureCallback != nil
    }
    
    /// Resumes the current data task.
    private func resumeTask() {
        if dataTask != nil && state == .paused {
            // The state that represents the task is downloading.
            state = .downloading
            CXDownloadDatabaseManager.shared.updateModel(model, option: .state)
            // Resumes the data task.
            dataTask?.resume()
        }
    }
    
    /// Pauses the current data task.
    func pauseTask() {
        dataTask?.suspend()
        state = .paused
        runOnMainThread { self.progressCallback?(self.model) }
        CXDownloadDatabaseManager.shared.updateModel(model, option: .state)
    }
    
    /// Cancels the current data task.
    func cancelTask() {
        if state == .waiting {
            state = .cancelled
            processError(withCode: NSURLErrorCancelled, message: "Cancel")
        } else if state == .downloading {
            dataTask?.cancel()
        }
    }
    
    func updateStateAsWaiting() {
        dataTask?.suspend()
        // Update state as waiting.
        state = .waiting
        runOnMainThread { self.progressCallback?(self.model) }
        CXDownloadDatabaseManager.shared.updateModel(model, option: .state)
    }
    
    private func finishDownloadTask() {
        finishCallback?(model)
    }
    
    private func getRequestURL() -> URL? {
        // This has been verified before invoking download's API.
        /* guard let urlString = model.url, let url = URL(string: urlString) else {
            CXDLogger.log(message: "The url is invalid.", level: .info)
            state = .error
            processError(withCode: -2000, message: "The url is invalid")
            return nil
        }*/
        return URL(string: model.url!)
    }
    
    private func tryResume(_ url: URL) -> Bool {
        if dataTask == nil {
            return false
        }
        // If the current data task exists.
        if let req = dataTask!.originalRequest, url == req.url {
            // If the download state is paused, resume the data task.
            if state == .paused {
                resumeTask()
                return true
            }
        } else {
            if state == .paused {
                resumeTask()
                return true
            }
        }
        return false
    }
    
    func process() {
        let url = getRequestURL()!
        CXDLogger.log(message: "url: \(url)", level: .info)
        if tryResume(url) { return }
        prepareToDownload(url)
    }
    
    private func prepareToDownload(_ url: URL) {
        // The dest file exists, this that indicates the download was completed.
        dstPath = CXDFileUtils.filePath(withURL: url, atDirectory: directory, fileName: fileName)
        CXDLogger.log(message: "DstPath: \(dstPath)", level: .info)
        if CXDFileUtils.fileExists(atPath: dstPath) {
            state = .finish
            model.progress = 1.0
            model.localPath = dstPath
            runOnMainThread {
                self.progressCallback?(self.model)
                self.successCallback?(self.model)
            }
            CXDownloadDatabaseManager.shared.updateModel(model, option: .allParams)
            notificationCenter.post(name: CXDownloadConfig.progressNotification, object: model)
            finishDownloadTask()
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
        dataTask = urlSession?.dataTask(with: urlRequest)
        // Adds an app-provided string value for the current task.
        dataTask?.taskDescription = model.url
        
        // The state that represents the task is downloading.
        state = .downloading
        CXDownloadDatabaseManager.shared.updateModel(model, option: .state)
        
        // Resume the data task
        dataTask?.resume()
    }
    
    /// Removes the temp file.
    private func removeTempFile() {
        CXDFileUtils.removeFile(atPath: tmpPath)
    }
    
    private func processError(withCode code: Int, message: String) {
        let stateInfo = CXDownloadStateInfo()
        stateInfo.code = code
        stateInfo.message = message
        model.stateInfo = stateInfo
        runOnMainThread { self.failureCallback?(self.model) }
        CXDownloadDatabaseManager.shared.updateModel(model, option: .state)
        finishDownloadTask()
    }
    
    deinit {
        CXDLogger.log(message: "\(type(of: self)): Deinited.", level: .info)
    }
    
}

extension CXDownloadTaskProcessor {
    
    func processSession(dataTask: URLSessionDataTask, didReceive response: URLResponse, completionHandler: @escaping (URLSession.ResponseDisposition) -> Void) {
        guard let resp = response as? HTTPURLResponse else {
            CXDLogger.log(message: "Fail to convert URLResponse to HTTPURLResponse.", level: .info)
            state = .error
            processError(withCode: -2001, message: "Fail to convert URLResponse to HTTPURLResponse")
            completionHandler(.cancel)
            return
        }
        
        //CXDLogger.log(message: "response.allHeaderFields: \(resp.allHeaderFields)", level: .info)
        // The total size.
        var totalSize = Int64((resp.allHeaderFields["Content-Length"] as? String) ?? "") ?? 0
        let contentRange = (resp.allHeaderFields["Content-Range"] as? String) ?? ""
        if !contentRange.isEmpty {
            if let lastComp = contentRange.components(separatedBy: "/").last {
                totalSize = Int64(lastComp) ?? 0
            }
        }
        
        // if the resumed file size is equal to the total size, executes it as follow.
        if totalSize > 0 && resumedFileSize == totalSize {
            CXDFileUtils.moveFile(from: tmpPath, to: dstPath)
            completionHandler(.cancel)
            state = .finish
            model.progress = 1.0
            model.localPath = dstPath
            runOnMainThread {
                self.progressCallback?(self.model)
                self.successCallback?(self.model)
            }
            CXDownloadDatabaseManager.shared.updateModel(model, option: .allParams)
            notificationCenter.post(name: CXDownloadConfig.progressNotification, object: model)
            finishDownloadTask()
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
            state = .downloading
            let progress = Float(resumedFileSize) / Float(totalSize)
            model.progress = progress
            runOnMainThread { self.progressCallback?(self.model) }
            CXDownloadDatabaseManager.shared.updateModel(model, option: .allParams)
            notificationCenter.post(name: CXDownloadConfig.progressNotification, object: model)
            outputStream = OutputStream.init(toFileAtPath: tmpPath, append: true)
            outputStream?.open()
            completionHandler(.allow)
            return
        }
        
        // 403, no permission access, ....
        CXDLogger.log(message: "An error occurs, the code is \(resp.statusCode).", level: .info)
        state = .error
        processError(withCode: resp.statusCode, message: "An error occurs")
        
        completionHandler(.cancel)
    }
    
    func processSession(dataTask: URLSessionDataTask, didReceive data: Data) {
        let receivedBytes = dataTask.countOfBytesReceived + resumedFileSize
        let allBytes = dataTask.countOfBytesExpectedToReceive + resumedFileSize
        model.totalFileSize = allBytes
        model.tmpFileSize = receivedBytes
        
        let dataLength = data.count
        // Calculates the size of the downloaded file within the speed time.
        model.intervalFileSize += Int64(dataLength)
        
        let intervals = CXDToolbox.getIntervalsWithTimestamp(model.lastSpeedTime)
        if intervals > 1 {
            // Calculates speed
            model.speed = model.intervalFileSize / intervals
            
            model.lastSpeedTime = CXDToolbox.getTimestampWithDate(Date())
        }
        
        let progress = Float(receivedBytes) / Float(allBytes)
        //CXDLogger.log(message: "progress: \(progress)", level: .info)
        model.progress = progress
        
        runOnMainThread { self.progressCallback?(self.model) }
        
        // Update the specified model in database.
        CXDownloadDatabaseManager.shared.updateModel(model, option: .progressData)
        notificationCenter.post(name: CXDownloadConfig.progressNotification, object: model)
        
        // Reset it.
        model.intervalFileSize = 0
        
        // Writes the received data to the temp file.
        let _ = data.withUnsafeBytes { [weak self] in
            if let baseAddress = $0.bindMemory(to: UTF8.self).baseAddress {
                self?.outputStream?.write(baseAddress, maxLength: dataLength)
            }
        }
    }
    
    func processSessionBecomeInvalid(with error: Error?) {
        // if error is nil, the url session become invalid.
        state = .error
        var code: Int = -2002
        var message = "The URL session become invalid"
        if let err = error as? NSError {
            code = err.code
            message = err.localizedDescription
        }
        processError(withCode: code, message: message)
    }
    
    func processSession(task: URLSessionTask, didCompleteWithError error: Error?) {
        outputStream?.close()
        // If no error, handle the successful logic.
        guard let error = error as? NSError else {
            CXDFileUtils.moveFile(from: tmpPath, to: dstPath)
            state = .finish
            model.localPath = dstPath
            runOnMainThread { self.successCallback?(self.model) }
            CXDownloadDatabaseManager.shared.updateModel(model, option: .state)
            finishDownloadTask()
            return
        }
        CXDLogger.log(message: "code: \(error.code), message: \(error.localizedDescription)", level: .error)
        
        // Cancels the data task.
        if error.code == NSURLErrorCancelled {
            state = .cancelled
        } else {
            // Occurs an error, etc.
            state = .error
        }
        processError(withCode: error.code, message: error.localizedDescription)
    }
    
}
