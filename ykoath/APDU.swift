//
//  APDU.swift
//  ykoath
//
//  Created on 11.07.2018.
//  Copyright © 2018 https://github.com/idf3d. All rights reserved.
//

import Foundation

enum YKInstruction: UInt8 {
    case put = 0x01
    case delete = 0x02
    case setCode = 0x03
    case reset = 0x04
    case list = 0xa1
    case calculate = 0xa2
    case validate = 0xa3
    case calculateAll = 0xa4
    case sendRemaining = 0xa5
}

class APDU {
    let cla: UInt8
    let ins: UInt8
    let p1: UInt8
    let p2: UInt8
    let lc: UInt8
    let data: Data

    var packetData: Data {
        var d = Data([cla, ins, p1, p2, lc])
        d.append(data)
        return d
    }

    init(cla: UInt8, ins: UInt8, p1: UInt8, p2: UInt8, lc: UInt8, data: Data) {
        self.cla = cla
        self.ins = ins
        self.p1 = p1
        self.p2 = p2
        self.lc = lc
        self.data = data
    }

    convenience init(ins inIns: UInt8, p1 inP1: UInt8, p2 inP2: UInt8, lc inLc: UInt8, data inData: Data) {
        self.init(cla: 0x0, ins: inIns, p1: inP1, p2: inP2, lc: inLc, data: inData)
    }

    convenience init(ins inIns: UInt8, p1 inP1: UInt8, p2 inP2: UInt8, data inData: Data) {
        let length = UInt8(inData.count)
        self.init(ins: inIns, p1: inP1, p2: inP2, lc: length, data: inData)
    }

    convenience init(_ ykIns: YKInstruction, p1 inP1: UInt8, p2 inP2: UInt8, data inData: Data) {
        self.init(ins: ykIns.rawValue, p1: inP1, p2: inP2, data: inData)
    }
}
