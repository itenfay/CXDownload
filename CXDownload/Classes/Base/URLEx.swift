//
//  URLEx.swift
//  CXDownload
//
//  Created by Tenfay on 2022/8/20.
//

import Foundation

extension URL {
    
    /// Return the path, or an empty string if the URL has an empty path.
    public var cxd_path: String {
        if #available(macOS 13.0, iOS 16.0, tvOS 16.0, watchOS 9.0, *) {
            return path(percentEncoded: false)
        } else {
            return path
        }
    }
    
    /// Return a Boolean value that indicates whether the resource is a directory.
    public var cxd_isDirectory: Bool! {
        return (try? resourceValues(forKeys: [.isDirectoryKey]))?.isDirectory
    }
    
    /// Returns a URL by appending the specified path component to self.
    public func cxd_appendingPathComponent(_ path: String) -> URL {
        if #available(macOS 13.0, iOS 16.0, tvOS 16.0, watchOS 9.0, *) {
            return appending(path: path, directoryHint: .inferFromPath)
        } else {
            return appendingPathComponent(path)
        }
    }
    
    /// Creates a file URL that references the local file or directory at path.
    public init(fileAtPath path: String) {
        if #available(macOS 13.0, iOS 16.0, tvOS 16.0, watchOS 9.0, *) {
            self.init(filePath: path, directoryHint: .inferFromPath, relativeTo: nil)
        } else {
            self.init(fileURLWithPath: path)
        }
    }
    
}
