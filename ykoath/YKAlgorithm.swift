//
//  YKAlgorithm.swift
//  ykoath
//
//  Created on 09.07.2018.
//  Copyright © 2018 https://github.com/idf3d. All rights reserved.
//

import Foundation

enum YKAlgorithm: UInt8 {
    case HMACSHA1 = 0x01
    case HMACSHA256 = 0x02
    case HMACSHA512 = 0x03

    init?(_ string: String) {
        switch string.uppercased() {
        case "SHA1":
            self = .HMACSHA1
        case "SHA256":
            self = .HMACSHA256
        case "SHA512":
            self = .HMACSHA512
        default:
            return nil
        }
    }
}
