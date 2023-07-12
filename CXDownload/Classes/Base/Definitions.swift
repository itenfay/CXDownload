//
//  Definitions.swift
//  CXDownload
//
//  Created by chenxing on 2022/8/20.
//

import Foundation

#if os(iOS) || os(tvOS)
import UIKit
public typealias CXDView = UIView
public typealias CXDButton = UIButton
public typealias CXDImageView = UIImageView
#elseif os(macOS)
import AppKit
public typealias CXDView = NSView
public typealias CXDButton = NSButton
public typealias CXDImageView = NSImageView
#else
#endif

@objcMembers public class CXDownloadConfig: NSObject {
    /// State change notification.
    public static let stateChangeNotification = Notification.Name("CXDownloadStateChangeNotification")
    /// Progress notification.
    public static let progressNotification = Notification.Name("CXDownloadProgressNotification")
    /// Max concurrent count change notification.
    public static let maxConcurrentCountChangeNotification = Notification.Name("CXDownloadMaxConcurrentCountChangeNotification")
    /// Allows cellular access change notification.
    public static let allowsCellularAccessChangeNotification = Notification.Name("CXDownloadAllowsCellularAccessChangeNotification")
    /// Networking reachability change notification. Please send the specified string(**"Reachable", "NotReachable", "ReachableViaWWAN" or "ReachableViaWiFi"**) by notification.object.
    public static let networkingReachabilityDidChangeNotification = Notification.Name("CXNetworkingReachabilityDidChangeNotification")
    /// Max concurrent count key.
    public static let maxConcurrentCountKey = "CXDownloadMaxConcurrentCountKey"
    /// Allows cellular access key.
    public static let allowsCellularAccessKey = "CXDownloadAllowsCellularAccessKey"
}

@objcMembers public class CXDToolbox: NSObject {
    
    /// Converts a byte count into the specified string format without creating an NSNumber object.
    public static func string(fromByteCount byteCount: Int64) -> String {
        return ByteCountFormatter.string(fromByteCount: byteCount, countStyle: ByteCountFormatter.CountStyle.file)
    }
    
    /// Converts a date into timestamp(us).
    public static func getTimestampWithDate(_ date: Date) -> TimeInterval {
        return date.timeIntervalSince1970 * 1000 * 1000
    }
    
    /// Converts a timestamp into date.
    public static func getDateWithTimestamp(_ ts: TimeInterval) -> Date {
        return Date(timeIntervalSince1970: ts * 0.001 * 0.001)
    }
    
    /// Gets intervals between a timestamp and the current time.
    public static func getIntervalsWithTimestamp(_ ts: TimeInterval) -> Int64 {
        return Int64(Date().timeIntervalSince(getDateWithTimestamp(ts)))
    }
    
}
