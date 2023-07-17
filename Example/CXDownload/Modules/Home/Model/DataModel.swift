//
//  DataModel.swift
//  CXDownload_Example
//
//  Created by chenxing on 2023/7/7.
//  Copyright © 2023 CocoaPods. All rights reserved.
//

import UIKit
import CXDownload

class DataModel: BaseModel {
    var vid: String = ""
    var url: String = ""
    var fileName: String = ""
    var directory: String = ""
    var localPath: String = ""
    var state: CXDownloadState = .default
    var speed: Int64 = 0
    var totalFileSize: Int64 = 0
    var tmpFileSize: Int64 = 0
    var progress: Float = 0
}

extension CXDownloadModel {
    
    func toDataModel(with vid: String) -> DataModel {
        let model = DataModel()
        model.vid = vid
        model.url = url ?? ""
        model.fileName = fileName ?? ""
        model.directory = directory ?? ""
        model.localPath = localPath ?? ""
        model.state = state
        model.speed = speed
        model.totalFileSize = totalFileSize
        model.tmpFileSize = tmpFileSize
        model.progress = progress
        return model
    }
    
}
