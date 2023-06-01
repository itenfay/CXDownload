//
//  CXDLogger.swift
//  CXDownload
//
//  Created by chenxing on 2022/8/10.
//

import Foundation

/// The level of the log.
public enum CXDLogLevel: CustomStringConvertible {
    case debug, info, warning, error
    
    public var description: String {
        switch self {
        case .debug: return "Debug"
        case .info: return "Info"
        case .warning: return "Warning"
        case .error: return "Error"
        }
    }
}

public struct CXDLogger {
    
    private static func log(prefix: String, message: String, level: CXDLogLevel) {
        let dateFormatter = DateFormatter.init()
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss.SSSSSSZ"
        let dateString = dateFormatter.string(from: Date())
        if CXDownloadManager.shared.configuration.enableLog {
            print("\(dateString) \(prefix) [CXD] [\(level.description)] \(message)")
        } else {
            if level == .debug {
                print("\(dateString) \(prefix) [CXD] [\(level.description)] \(message)")
            }
        }
    }
    
    /// Outputs the log to the console.
    public static func log(message: String, level: CXDLogLevel, file: String = #file, method: String = #function, lineNumber: Int = #line) {
        let fileName = (file as NSString).lastPathComponent
        log(prefix: "[F: \(fileName) M: \(method) L: \(lineNumber)]", message: message, level: level)
    }
    
    /// Outputs the log to the console.
    public static func log(obj: Any, message: String, level: CXDLogLevel) {
        log(prefix: "[\(type(of: obj))]", message: message, level: level)
    }
    
}
