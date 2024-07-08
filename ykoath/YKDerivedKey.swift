//
//  YKDerivedKey.swift
//  ykoath
//
//  Created on 10.07.2018.
//  Copyright © 2018 https://github.com/idf3d. All rights reserved.
//

import Foundation
import CommonCrypto

class YKDerivedKey {
    let keyData: Data

    init(salt: Data, password: String) {
        keyData = YKDerivedKey.pbkdf2SHA1(password: password, salt: salt, keyByteCount: 16, rounds: 1000)
    }

    init(_ data: Data) {
        keyData = data
    }

    private class func pbkdf2SHA1(password: String, salt: Data, keyByteCount: Int, rounds: Int) -> Data {
        return pbkdf2(hash:CCPBKDFAlgorithm(kCCPRFHmacAlgSHA1), password:password, salt:salt, keyByteCount:keyByteCount, rounds:rounds)
    }

    private class func pbkdf2(hash: CCPBKDFAlgorithm, password: String, salt: Data, keyByteCount: Int, rounds: Int) -> Data {
        guard let passwordData = password.data(using:String.Encoding.utf8) else {
            return Data()
        }
        var derivedKeyData = Data(repeating:0, count:keyByteCount)

        let derivationStatus = derivedKeyData.withUnsafeMutableBytes { derivedKeyBytesRaw -> Int in
            let derivedKeyBytes = derivedKeyBytesRaw.bindMemory(to: UInt8.self).baseAddress
            return salt.withUnsafeBytes { saltBytesRaw -> Int in
                let saltBytes = saltBytesRaw.bindMemory(to: UInt8.self).baseAddress

                return Int(CCKeyDerivationPBKDF(
                            CCPBKDFAlgorithm(kCCPBKDF2),
                            password, passwordData.count,
                            saltBytes, salt.count,
                            hash,
                            UInt32(rounds),
                            derivedKeyBytes, keyByteCount))
            }
        }
        if (derivationStatus != 0) {
            return Data();
        }

        return derivedKeyData
    }
}
