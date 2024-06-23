//
//  Download+CXDL.swift
//  CXDownload
//
//  Created by Tenfay on 2022/8/20.
//

import Foundation

/// Declares a `CXDownloadBase` struct.
public struct CXDownloadBase<T> {
    public let base: T
    
    public init(_ base: T) {
        self.base = base
    }
}

/// Declares a `CXDownloadBaseCompatible` protocol.
public protocol CXDownloadBaseCompatible {
    associatedtype M
    
    static var dl: CXDownloadBase<M>.Type { get set }
    var dl: CXDownloadBase<M> { get set }
}

/// Implements this protocol by default.
public extension CXDownloadBaseCompatible {
    
    static var dl: CXDownloadBase<Self>.Type {
        get { return CXDownloadBase<Self>.self }
        set {}
    }
    
    var dl: CXDownloadBase<Self> {
        get { return CXDownloadBase<Self>.init(self) }
        set {}
    }
    
}

#if os(iOS) || os(tvOS) || os(macOS)
/// The view conforms the `CXDownloadBaseCompatible` protocol.
extension CXDView: CXDownloadBaseCompatible {}
#endif
