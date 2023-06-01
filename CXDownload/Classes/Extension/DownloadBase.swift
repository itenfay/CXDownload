//
//  DownloadBase.swift
//  CXDownload
//
//  Created by chenxing on 2022/8/20.
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

/// The UIView follows this `CXDownloadBaseCompatible` protocol.
extension UIView: CXDownloadBaseCompatible {}

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
