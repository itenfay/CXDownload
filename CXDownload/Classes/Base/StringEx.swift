//
//  StringEx.swift
//  CXDownload
//
//  Created by Tenfay on 2022/8/10.
//

import Foundation
#if canImport(CommonCrypto)
import CommonCrypto
#endif

extension String {
    
    /// Returns a optinal md5 string. Clients should migrate to SHA256 (or stronger)
    public var cxd_md5: String? {
        #if canImport(CommonCrypto)
        guard let utf8 = cString(using: .utf8) else { return nil }
        var digest = [UInt8](repeating: 0, count: Int(CC_MD5_DIGEST_LENGTH))
        CC_MD5(utf8, CC_LONG(utf8.count - 1), &digest)
        return digest.reduce("") { $0 + String(format: "%02X", $1) }
        #else
        return nil
        #endif
    }
    
    /// Returns a optinal sha2 string.
    public var cxd_sha2: String? {
        #if canImport(CommonCrypto)
        guard let utf8 = cString(using: .utf8) else { return nil }
        var digest = [UInt8](repeating: 0, count: Int(CC_SHA256_DIGEST_LENGTH))
        CC_SHA256(utf8, CC_LONG(utf8.count - 1), &digest)
        return digest.reduce("") { $0 + String(format: "%02X", $1) }
        #else
        return nil
        #endif
    }
    
}
