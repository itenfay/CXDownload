//
//  CXDownloadModel.swift
//  CXDownload
//
//  Created by chenxing on 2023/6/28.
//

import Foundation
#if canImport(FMDB)
import FMDB
#endif

@objcMembers public class CXDownloadStateInfo: NSObject {
    public var code: Int = 0
    public var message: String = ""
}

@objcMembers public class CXDownloadModel: NSObject {
    /// The identifier of file.
    public var fid: String?
    /// The name of file.
    public var fileName: String?
    /// The url of file.
    public var url: String?
    /// The local path of file.
    public var localPath: String?
    /// The total size of file.
    public var totalFileSize: Int64 = 0
    /// The resumed size of file.
    public var tmpFileSize: Int64 = 0
    /// The progress of downloading, The value is 0..1.
    public var progress: Float = 0
    /// The speed of downloading.
    public var speed: Int64 = 0
    /// The state for the download.
    public var state: CXDownloadState = .waiting
    /// The state information for the download.
    public var stateInfo: CXDownloadStateInfo?
    /// The last timestamp for calculating speed.
    public var lastSpeedTime: TimeInterval = 0
    /// The file size of speed time.
    public var intervalFileSize: Int64 =  0
    /// Records the time when the task is ready to download (Click, Pause and Failed), which is used to calculate the sequence of starting and stopping the task.
    public var lastStateTime: Int64 = 0
    
    public override init() {
        super.init()
    }
    
    #if canImport(FMDB)
    public init(resultSet: FMResultSet) {
        self.fid = resultSet.string(forColumn: "fid")
        self.fileName = resultSet.string(forColumn: "fileName")
        self.url = resultSet.string(forColumn: "url")
        self.totalFileSize = resultSet.longLongInt(forColumn: "totalFileSize")
        self.tmpFileSize = resultSet.longLongInt(forColumn: "tmpFileSize")
        self.progress = Float(resultSet.double(forColumn: "progress"))
        self.state = CXDownloadState(rawValue: resultSet.long(forColumn: "state")) ?? .waiting
        self.lastSpeedTime = resultSet.double(forColumn: "lastSpeedTime")
        self.intervalFileSize = resultSet.longLongInt(forColumn: "intervalFileSize")
        self.lastStateTime = resultSet.longLongInt(forColumn: "lastStateTime")
    }
    #endif
}
