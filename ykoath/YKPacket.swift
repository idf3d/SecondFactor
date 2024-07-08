//
//  YKPacket.swift
//  ykoath
//
//  Created on 11.07.2018.
//  Copyright © 2018 https://github.com/idf3d. All rights reserved.
//

import Foundation

class YKPacket {
    enum Tag: UInt8 {
        case name = 0x71
        case key = 0x73
        case challenge = 0x74
        case challengeResponse = 0x75
    }

    let tag: UInt8
    let data: Data

    var packetData: Data {
        var d = Data([tag, UInt8(data.count)])
        d.append(data)
        return d
    }

    init(tag: UInt8, data: Data) {
        self.tag = tag
        self.data = data
    }

    convenience init(_ yTag: Tag, data: Data) {
        self.init(tag: yTag.rawValue, data: data)
    }
}
