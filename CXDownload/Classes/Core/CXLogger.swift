//
//  CXLogger.swift
//  CXDownload
//
//  Created by chenxing on 2022/8/10.
//

import Foundation

/// The level of the log.
public enum CXLogLevel {
    case info, warning, error
    
    var description: String {
        switch self {
        case .info: return "Info"
        case .warning: return "Warning"
        case .error: return "Error"
        }
    }
}

public struct CXLogger {
    
    private static func log(message: String, level: CXLogLevel) {
        if CXDownloaderManager.shared.configuration.enableLog {
            print("[CX] [\(level.description)] \(message)")
        } else {
            if level == .error {
                print("[CX] [\(level.description)] \(message)")
            }
        }
    }
    
    /// Outputs the log to the console.
    public static func log(message: String, level: CXLogLevel, file: String = #file, method: String = #function, lineNumber: Int = #line) {
        let fileName = (file as NSString).lastPathComponent
        log(message: "[F: \(fileName) M: \(method) L: \(lineNumber)] \(message)", level: level)
    }
    
    /// Outputs the log to the console.
    public static func log(obj: Any, message: String, level: CXLogLevel) {
        log(message: "\(type(of: obj)) \(message)", level: level)
    }
    
}
