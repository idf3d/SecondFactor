//
//  YKCalculate.swift
//  ykoath
//
//  Created on 19.08.2018.
//  Copyright © 2018 https://github.com/idf3d. All rights reserved.
//

import Foundation

class YKCalculate {
    class Request {
        let data: Data

        convenience init?(label: String) {
            guard let lData = label.data(using: .utf8) else {
                return nil
            }
            self.init(label: lData)
        }

        init(label: Data) {
            let namePacket = YKPacket(.name, data: label)
            let challenePacket = YKPacket(.challenge, data: Data.timeChallenge())

            var apduData = Data(namePacket.packetData)
            apduData.append(challenePacket.packetData)

            let req = APDU(.calculate, p1: 0x00, p2: 0x01, data: apduData)

            self.data = req.packetData
        }
    }

    class Response {
        let code: Int?
        let codeLen: Int?
        let error: Error?

        init(_ response: APDUResponse) {
            self.error = response.error

            guard var data = response.consume(dataForTag: 0x76),
                    data.count > 1 else {
                code = nil
                codeLen = nil
                return
            }

            self.codeLen = Int(data.removeFirst())
            self.code = data.withUnsafeBytes { ptr -> Int in
                let typed = ptr.bindMemory(to: UInt32.self)
                return Int(CFSwapInt32BigToHost(typed[0]))
            }
        }
    }
}
