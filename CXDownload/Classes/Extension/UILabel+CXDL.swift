//
//  UILabel+CXDL.swift
//  CXDownload
//
//  Created by chenxing on 2022/8/20.
//

import Foundation

public extension CXDownloadBase where T : UILabel {
    
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
        return CXDownloaderManager.shared.asyncDownload(url: url, customDirectory: targetDirectory, customFileName: customFileName, progress: { [weak _base = self.base] _progress in
            let _progress_ = Int(_progress * 100)
            _base?.text = "\(_progress_)%"
            progress(_progress_)
        }, success: { filePath in
            success(filePath)
        }) { error in
            failure(error)
        }
    }
    
}
