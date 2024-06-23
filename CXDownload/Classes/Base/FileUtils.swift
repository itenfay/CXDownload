//
//  FileUtils.swift
//  CXDownload
//
//  Created by Tenfay on 2022/8/15.
//

import Foundation

@objcMembers public class CXDFileUtils: NSObject {
    
    /// The path extension of the URL, or an empty string if the path is an empty string.
    public class func pathExtension(_ url: URL) -> String {
        return url.pathExtension
    }
    
    /// A new string made by deleting the extension (if any, and only the last) from the receiver.
    public class func fileName(_ url: URL) -> String {
        return (url.lastPathComponent as NSString).deletingPathExtension
    }
    
    /// The last path component of the URL, or an empty string if the path is an empty string.
    public class func lastPathComponent(_ url: URL) -> String {
        return url.lastPathComponent
    }
    
    /// Returns a Boolean value that indicates whether a file or directory exists at a specified path.
    public class func fileExists(atPath path: String) -> Bool {
        return FileManager.default.fileExists(atPath: path)
    }
    
    /// Returns the path to either the user’s or application’s home directory, depending on the platform.
    public class func homeDirectory() -> String {
        return NSHomeDirectory()
    }
    
    /// Returns the path of the temporary directory for the current user.
    public class func tempDirectory() -> String {
        return NSTemporaryDirectory()
    }
    
    /// Returns the path of the document directory for the current user.
    public class func documentDirectory() -> String {
        return NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0]
    }
    
    /// Returns the path of the caches directory for the current user.
    public class func cachesDirectory() -> String {
        return NSSearchPathForDirectoriesInDomains(.cachesDirectory, .userDomainMask, true)[0]
    }
    
    /// Creates a directory at the specified path.
    public class func createDirectory(atPath path: String) -> Bool {
        do {
            var isDir: ObjCBool = false
            let isDirExist = FileManager.default.fileExists(atPath: path, isDirectory: &isDir)
            if isDirExist && isDir.boolValue {}
            else {
                try FileManager.default.createDirectory(at: URL(fileAtPath: path), withIntermediateDirectories: true)
            }
            return true
        } catch {
            CXDLogger.log(message: "\(error)", level: .error)
        }
        return false
    }
    
    /// Creates a cache directory with the given path component and returns the specified URL.
    public class func cachePath(withPathComponent pathComponent: String = "cx.download.caches") -> URL? {
        do {
            let cacheURL = try FileManager.default.url(for: .cachesDirectory,
                                                       in: .userDomainMask,
                                                       appropriateFor: nil,
                                                       create: false)
            let dstURL = cacheURL.appendingPathComponent(pathComponent)
            var isDir: ObjCBool = false
            let isDirExist = FileManager.default.fileExists(atPath: dstURL.cxd_path, isDirectory: &isDir)
            if isDirExist && isDir.boolValue {}
            else {
                try FileManager.default.createDirectory(at: dstURL, withIntermediateDirectories: true)
            }
            return dstURL
        } catch {
            CXDLogger.log(message: "\(error)", level: .error)
        }
        return nil
    }
    
    /// Returns a destination file path by the remote url, directory, custom file name.
    public class func filePath(withURL url: URL, atDirectory directory: String? = nil, fileName: String? = nil) -> String {
        var cachePath: URL?
        if let dir = directory, !dir.isEmpty {
            cachePath = self.cachePath(withPathComponent: dir)
        } else {
            cachePath = self.cachePath()
        }
        var filePathURL: URL?
        if let fn = fileName, !fn.isEmpty {
            let ext = self.pathExtension(url)
            filePathURL = cachePath?.appendingPathComponent(ext.isEmpty ? fn : fn + "." + ext)
        } else {
            let file = self.lastPathComponent(url)
            filePathURL = cachePath?.appendingPathComponent(file)
        }
        return filePathURL?.cxd_path ?? ""
    }
    
    /// The file’s size in bytes.
    public class func fileSize(_ filePath: String) -> Int64 {
        var fileSizeBytes: Int64 = 0
        let fileManager = FileManager.default
        if !fileManager.fileExists(atPath: filePath) {
            return fileSizeBytes
        }
        do {
            let attriDict = try fileManager.attributesOfItem(atPath: filePath)
            fileSizeBytes = attriDict[.size] as? Int64 ?? 0
        } catch let error {
            CXDLogger.log(message: "\(error)", level: .error)
        }
        return fileSizeBytes
    }
    
    /// Moves the file or directory at the specified path to a new location synchronously.
    public class func moveFile(from srcPath: String, to dstPath: String) {
        let fileManager = FileManager.default
        if !fileManager.fileExists(atPath: srcPath) { return }
        do {
            try fileManager.moveItem(atPath: srcPath, toPath: dstPath)
        } catch {
            CXDLogger.log(message: "\(error)", level: .error)
        }
    }
    
    /// Removes the file or directory at the specified path.
    public class func removeFile(atPath path: String) {
        let fileManager = FileManager.default
        if !fileManager.fileExists(atPath: path) { return }
        do {
            try fileManager.removeItem(atPath: path)
        } catch {
            CXDLogger.log(message: "\(error)", level: .error)
        }
    }
    
    /// Writes the specified data synchronously to the file handle.
    public class func write(data: Data, atPath path: String) {
        do {
            let fileHandle = try FileHandle(forUpdating: URL(fileAtPath: path))
            if #available(macOS 10.15.4, iOS 13.4, watchOS 6.2, tvOS 13.4, *) {
                try fileHandle.seekToEnd()
                try fileHandle.write(contentsOf: data)
                // macos(10.15), ios(13.0), watchos(6.0), tvos(13.0)
                try fileHandle.close()
            } else {
                fileHandle.seekToEndOfFile()
                fileHandle.write(data)
                fileHandle.closeFile()
            }
        } catch let error {
            CXDLogger.log(message: "\(error)", level: .error)
        }
    }
    
}
