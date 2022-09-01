//
//  String+Cx.swift
//  CXDownload
//
//  Created by chenxing on 2022/8/10.
//

import Foundation
import CommonCrypto

public extension String {
    
    /// Returns a optinal md5 string.
    var cx_md5: String? {
        guard let utf8 = cString(using: .utf8) else { return nil }
        var digest = [UInt8](repeating: 0, count: Int(CC_MD5_DIGEST_LENGTH))
        CC_MD5(utf8, CC_LONG(utf8.count - 1), &digest)
        return digest.reduce("") { $0 + String(format: "%02X", $1) }
    }
    
}
