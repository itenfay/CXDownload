//
//  CXDownloadTaskProcessor.swift
//  CXDownload
//
//  Created by chenxing on 2023/6/28.
//

import Foundation

protocol ICXDownloadTaskProcessor {
    var urlSession: URLSession? { get set }
    var url: String? { get }
    var state: CXDownloadState { get set }
}

class CXDownloadTaskProcessor: ICXDownloadTaskProcessor {
    
    private var progressCallback: CXDownloadCallback?
    private var successCallback: CXDownloadCallback?
    private var failureCallback: CXDownloadCallback?
    private var finishCallback: CXDownloadCallback?
    
    private var resumedFileSize: Int64 = 0
    /// The destination file path.
    private var dstPath: String = ""
    /// The temp file path.
    private var tmpPath: String = ""
    
    private(set) var atDirectory: String?
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
    init(
        model: CXDownloadModel,
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
    convenience init(
        model: CXDownloadModel,
        atDirectory: String?,
        fileName: String?,
        progess: CXDownloadCallback?,
        success: CXDownloadCallback?,
        failure: CXDownloadCallback?,
        finish: CXDownloadCallback?)
    {
        self.init(model: model, progess: progess, success: success, failure: failure, finish: finish)
        self.atDirectory = atDirectory
        self.fileName = fileName
    }
    
    func updateModelStateAndTime(_ downloadModel: CXDownloadModel) {
        downloadModel.state = .waiting
        downloadModel.lastStateTime = Int64(CXDToolbox.getTimestampWithDate(Date()))
        model = downloadModel
        CXDownloadDatabaseManager.shared.updateModel(model, option: [.state, .lastStateTime])
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
    private func pauseTask() {
        if dataTask != nil && state == .downloading {
            state = .paused
            CXDownloadDatabaseManager.shared.updateModel(model, option: .state)
            dataTask?.suspend()
        }
    }
    
    /// Cancels the current data task.
    func cancelTask() {
        dataTask?.cancel()
    }
    
    private func finishTask() {
        finishCallback?(model)
    }
    
    private func getRequestURL() -> URL? {
        // This has been verified before invoking download's API.
        /* guard let urlString = model.url, let url = URL(string: urlString) else {
            CXDLogger.log(message: "The url is invalid.", level: .info)
            state = .error
            let stateInfo = CXDownloadStateInfo()
            stateInfo.code = -2000
            stateInfo.message = "The url is invalid"
            model.stateInfo = stateInfo
            runOnMainThread {
                self.failureCallback?(self.model)
            }
            CXDownloadDatabaseManager.shared.updateModel(model, option: .state)
            finishTask()
            return nil
        }*/
        return URL(string: model.url!)
    }
    
    func process() {
        let url = getRequestURL()!
        CXDLogger.log(message: "url: \(url)", level: .info)
        
        if dataTask != nil {
            // If the current data task exists.
            if let req = dataTask!.originalRequest, url == req.url {
                // If the download state is paused, resume the data task.
                if state == .paused {
                    resumeTask()
                    return
                }
            } else {
                if state == .paused {
                    resumeTask()
                    return
                }
            }
        }
        
        prepareToDownload(url)
    }
    
    private func prepareToDownload(_ url: URL) {
        // The dest file exists, this that indicates the download was completed.
        dstPath = CXDFileUtils.filePath(withURL: url, atDirectory: atDirectory, fileName: fileName)
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
            finishTask()
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
    
    func processSession(dataTask: URLSessionDataTask, didReceive response: URLResponse, completionHandler: @escaping (URLSession.ResponseDisposition) -> Void) {
        guard let resp = response as? HTTPURLResponse else {
            CXDLogger.log(message: "Fail to convert URLResponse to HTTPURLResponse.", level: .info)
            completionHandler(.cancel)
            state = .error
            let stateInfo = CXDownloadStateInfo()
            stateInfo.code = -2001
            stateInfo.message = "Fail to convert URLResponse to HTTPURLResponse"
            model.stateInfo = stateInfo
            runOnMainThread {
                self.failureCallback?(self.model)
            }
            CXDownloadDatabaseManager.shared.updateModel(model, option: .state)
            finishTask()
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
            finishTask()
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
            runOnMainThread {
                self.progressCallback?(self.model)
            }
            CXDownloadDatabaseManager.shared.updateModel(model, option: .allParams)
            outputStream = OutputStream.init(toFileAtPath: tmpPath, append: true)
            outputStream?.open()
            completionHandler(.allow)
            return
        }
        
        // 403, no permission access, ....
        CXDLogger.log(message: "An error occurs, the code is \(resp.statusCode).", level: .info)
        state = .error
        let stateInfo = CXDownloadStateInfo()
        stateInfo.code = resp.statusCode
        stateInfo.message = "An error occurs"
        model.stateInfo = stateInfo
        runOnMainThread {
            self.failureCallback?(self.model)
        }
        CXDownloadDatabaseManager.shared.updateModel(model, option: .state)
        finishTask()
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
        
        runOnMainThread {
            self.progressCallback?(self.model)
        }
        
        // Update the specified model in database.
        CXDownloadDatabaseManager.shared.updateModel(model, option: .progressData)
        NotificationCenter.default.post(name: CXDownloadConfig.progressNotification, object: model)
        
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
        let stateInfo = CXDownloadStateInfo()
        if let err = error as? NSError {
            stateInfo.code = err.code
            stateInfo.message = err.localizedDescription
        } else {
            stateInfo.code = -2002
            stateInfo.message = "The URL session become invalid"
        }
        model.stateInfo = stateInfo
        runOnMainThread {
            self.failureCallback?(self.model)
        }
        CXDownloadDatabaseManager.shared.updateModel(model, option: .state)
        finishTask()
    }
    
    func processSession(task: URLSessionTask, didCompleteWithError error: Error?) {
        outputStream?.close()
        // If no error, handle the successful logic.
        guard let error = error as? NSError else {
            CXDFileUtils.moveFile(from: tmpPath, to: dstPath)
            state = .finish
            model.localPath = dstPath
            runOnMainThread {
                self.successCallback?(self.model)
            }
            CXDownloadDatabaseManager.shared.updateModel(model, option: .state)
            finishTask()
            return
        }
        // Cancels the data task.
        if error.code == NSURLErrorCancelled {
            dataTask = nil
            CXDLogger.log(message: "Code: \(error.code), message: \(error.localizedDescription)", level: .info)
        } else {
            // Occurs an error, etc.
            state = .error
            let stateInfo = CXDownloadStateInfo()
            stateInfo.code = error.code
            stateInfo.message = error.localizedDescription
            model.stateInfo = stateInfo
            runOnMainThread {
                self.failureCallback?(self.model)
            }
            CXDownloadDatabaseManager.shared.updateModel(model, option: .state)
            finishTask()
        }
    }
    
    deinit {
        CXDLogger.log(message: "\(type(of: self)): Deinited.", level: .info)
    }
    
}
