//
//  Keychain.swift
//  ykoath
//
//  Created on 31.07.2018.
//  Copyright © 2018 https://github.com/idf3d. All rights reserved.
//

import Foundation
import Security

private let kSecClassValue = kSecClass as String
private let kSecAttrAccountValue = kSecAttrAccount as String
private let kSecValueDataValue = kSecValueData as String
private let kSecClassGenericPasswordValue =  kSecClassGenericPassword as String
private let kSecAttrServiceValue = kSecAttrService as String
private let kSecMatchLimitValue = kSecMatchLimit as String
private let kSecReturnDataValue = kSecReturnData as String
private let kSecMatchLimitOneValue = kSecMatchLimitOne as String
private let kSecAttrSynchronizableValue = kSecAttrSynchronizable as String

class KeychainItem {
    enum KeychainError: Error {
        case unexpected
        case incorrectData
        case error(String)
    }

    let name: String

    init (_ name: String) {
        self.name = name
    }

    private var defaultQuery: [String: Any] {
        var query = [String: Any]()

        query[kSecClassValue] = kSecClassGenericPasswordValue
        query[kSecAttrAccountValue] = name
      //query[kSecAttrSynchronizableValue] = kCFBooleanTrue

        return query
    }

    private func checkStatus(_ status: OSStatus) throws {
        if (status != errSecSuccess) {
            if let err = SecCopyErrorMessageString(status, nil) {
                throw KeychainError.error(err as String)
            } else {
                throw KeychainError.unexpected
            }
        }
    }

    func remove() throws {
        let status = SecItemDelete(defaultQuery as CFDictionary)
        try checkStatus(status)
    }

    func save(_ dataToSave: Data) throws {
        guard let convertedData = dataToSave.hexString().data(using: .utf8) else {
            throw KeychainError.incorrectData
        }
        let loaded = data()

        if convertedData == dataToSave {
            return
        }

        let status: OSStatus

        if loaded == nil {
            var query = defaultQuery
            query[kSecValueDataValue] = convertedData
            status = SecItemAdd(query as CFDictionary, nil)
        } else {
            status = SecItemUpdate(defaultQuery as CFDictionary, [kSecValueDataValue:convertedData] as CFDictionary)
        }
        try checkStatus(status)
    }

    func data() -> Data? {
        var query = defaultQuery
        query[kSecReturnDataValue] = kCFBooleanTrue
        query[kSecMatchLimitValue] = kSecMatchLimitOneValue

        var dataTypeRef :AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &dataTypeRef)

        guard status == errSecSuccess else {
            return nil
        }

        guard let rawData = dataTypeRef as? Data,
            let hexStr = String(bytes: rawData, encoding: .utf8)  else {
            return nil
        }

        return Data(hexString: hexStr)
    }

    func key() -> YKDerivedKey? {
        guard let data = data() else {
            return nil
        }

        return YKDerivedKey(data)
    }

    func save(_ key: YKDerivedKey) throws {
        try self.save(key.keyData)
    }
}
