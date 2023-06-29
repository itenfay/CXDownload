//
//  CXDownloadModel.swift
//  CXDownload
//
//  Created by chenxing on 2023/6/28.
//

import UIKit

@objcMembers public class CXDownloadModel: NSObject {
    
    public var identifer: String = ""
    public var url: String = ""
    public var hashCode: String = ""
    public var filePath: String = ""
    public var totalFileSize: Int64 = 0
    public var tmpFileSize: Int64 = 0
    public var progress: Float = 0
    
}
