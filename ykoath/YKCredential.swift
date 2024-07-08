//
//  YKCredentials.swift
//  ykoath
//
//  Created on 14.07.2018.
//  Copyright © 2018 https://github.com/idf3d. All rights reserved.
//

import Foundation

class YKCredential {
    enum CredentialType: UInt8 {
        case totp = 0x20
        case hotp = 0x10

        init?(_ typeString: String) {
            switch typeString {
            case "totp":
                self = .totp
            //case "hotp":
                //self = .hotp
            default:
                return nil
            }
        }
    }

    let type: CredentialType
    let issuer: String?
    let account: String
    let algorithm: YKAlgorithm?
    let secret: Data?
    let digits: Int
    let period: Int

    private let rawCode: Int?
    var code: String? {
        guard let c = rawCode else {
                return nil
        }

        var s = String(c)

        while s.count < digits {
            s = "0" + s
        }

        return s
    }

    init(label: String, type: CredentialType, code: Int?, codeLen: Int) {
        self.type = type

        let (aName, issuer, period) = YKCredential.parseLabel(label)

        if period == 30 {
            self.rawCode = code
        } else {
            print("Unsupported period")
            self.rawCode = nil
        }

        self.account = aName
        self.issuer = issuer
        self.digits = codeLen
        self.algorithm = nil
        self.secret = nil
        self.period = period
    }

    init(_ cred: YKCredential, rawCode: Int, codeLen: Int) {
        self.type = cred.type
        self.issuer = cred.issuer
        self.account = cred.account
        self.algorithm = cred.algorithm
        self.secret = nil
        self.digits = codeLen
        self.period = cred.period
        self.rawCode = rawCode
    }

    convenience init?(withString string: String) {
        guard let url = URL(string: string) else {
            return nil
        }

        self.init(withURL: url)
    }

    init?(withURL url: URL) {
        guard url.scheme == "otpauth" else {
            return nil
        }

        guard let strType = url.host,
            let type = CredentialType(strType) else {
                return nil
        }

        self.type = type
        self.rawCode = nil

        let label = url.lastPathComponent

        let (aName, issuer1, _) = YKCredential.parseLabel(label)

        self.account = aName

        let components = url.parameters

        guard let key = components["secret"],
            let keyData = Data(base32Encoded: key) else {
            return nil
        }

        self.secret = keyData

        if let issuer2 = components["issuer"] {
            self.issuer = issuer2
        } else {
            self.issuer = issuer1
        }

        if let algoStr = components["algorithm"], let algo = YKAlgorithm(algoStr) {
            self.algorithm = algo
        } else {
            self.algorithm = .HMACSHA1
        }

        if let dStr = components["digits"], let digits = Int(dStr) {
            self.digits = digits
        } else {
            self.digits = 6
        }

        // components["counter"] REQUIRED for HOTP

        if let pStr = components["period"], let period = Int(pStr) {
            self.period = period
        } else {
            self.period = 30
        }
    }

    // returns: account name, issuer
    private class func parseLabel(_ label: String) -> (String, String?, Int) {
        let parts1 = label.split(separator: "/")
        let input: String
        let codeLen: Int

        if parts1.count > 1 {
            input = String(parts1[1])
            codeLen = Int(parts1[0]) ?? 30
        } else {
            input = label
            codeLen = 30
        }

        let parts = input.split(separator: ":")

        switch parts.count {
        case 1:
            return (String(parts[0]), nil, codeLen)
        case 2:
            return (String(parts[1]), String(parts[0]), codeLen)
        default:
            return (label, nil, codeLen)// incorrect input
        }
    }

    var ykLabel: String {
        var result = ""
        if period > 0 && period != 30 {
            result.append(String(format: "%i/",period))
        }

        if let issuer = issuer {
            result.append(issuer)
            result.append(":")
        }

        result.append(account)

        return result
    }
}
