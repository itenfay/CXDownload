//
//  CXDDefinitions.swift
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
