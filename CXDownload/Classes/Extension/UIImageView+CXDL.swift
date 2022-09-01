//
//  UIImageView+CXDL.swift
//  CXDownload
//
//  Created by chenxing on 2022/8/20.
//

import Foundation

public extension CXDownloadBase where T : UIImageView {
    
    /// Executes an asynchronous download by the url and other parameters.
    @discardableResult
    func download(
        url: String,
        to targetDirectory: String? = nil,
        customFileName: String? = nil,
        progress: @escaping (_ progress: Int) -> Void,
        success: @escaping CXDownloader.SuccessClosure,
        failure: @escaping CXDownloader.FailureClosure
    ) -> CXDownloader? {
        return CXDownloaderManager.shared.asyncDownload(url: url, customDirectory: targetDirectory, customFileName: customFileName, progress: { _progress in
            progress(Int(_progress * 100))
        }, success: { filePath in
            success(filePath)
        }) { error in
            failure(error)
        }
    }
    
}
