//
//  APDUResponse.swift
//  ykoath
//
//  Created on 11.07.2018.
//  Copyright © 2018 https://github.com/idf3d. All rights reserved.
//

import Foundation

class APDUResponse {
    private(set) var code: UInt16 = 0x0
    private var data: Data = Data()
    private var consumableData: Data = Data()

    private(set) var needsMoreData: Bool = true
    private(set) var success: Bool = false
    private(set) var error: YKError? = nil

    private class func consumeCode(_ inData: Data) -> (Data, UInt16) {
        guard inData.count >= 2 else {
            return (inData, 0x0)
        }

        var d = inData
        let b1 = d.removeLast()
        let b2 = d.removeLast()

        let c = UInt16(b2) << 8 + UInt16(b1)

        return (d, c)
    }

    convenience init(_ inData: Data) {
        self.init()
        self.append(inData)
    }

    func append(_ inData: Data) {
        let (rawData, code) = APDUResponse.consumeCode(inData)
        data.append(rawData)
        consumableData.append(rawData)
        self.code = code

        switch self.code {
        case 0x9000:
            success = true
            needsMoreData = false
        case 0x6100...0x61ff:
            success = false
            needsMoreData = true
        default:
            success = false
            needsMoreData = false
            error = YKError(self.code)
        }
    }

    func consume() -> UInt8? {
        if consumableData.isEmpty {
            return nil
        }

        return consumableData.removeFirst()
    }

    func consume(_ i: Int) -> Data? {
        guard consumableData.count >= i else {
            return nil
        }

        var result = Data()

        for _ in 0..<i {
            result.append(consumableData.removeFirst())
        }

        return result
    }

    func consume(dataForTag tag: UInt8) -> Data? {
        guard consumableData.first == tag else {
            return nil
        }

        _ = consume()

        guard let len = consume() else {
            return nil
        }

        return consume(Int(len))
    }

}
