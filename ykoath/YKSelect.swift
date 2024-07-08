//
//  YKSelect.swift
//  ykoath
//
//  Created on 09.07.2018.
//  Copyright © 2018 https://github.com/idf3d. All rights reserved.
//

import Foundation

class YKSelect {
    class Request {
        let data: Data

        init() {
            let aid = Data([0xa0, 0x00, 0x00, 0x05, 0x27, 0x21, 0x01])
            let apdu = APDU(ins: 0xa4, p1: 0x04, p2: 0x00, data: aid)
            data = apdu.packetData
        }
    }

    class Response {
        let version: Data
        let name: Data
        let challenge: Data?
        let algorithm: YKAlgorithm?

        let identifier: String

        var isRequiresValidation: Bool {
            return challenge != nil
        }

        init?(_ data: Data) {
            let response = APDUResponse(data)

            guard response.success else {
                return nil
            }

            guard let vData = response.consume(dataForTag: 0x79),
                let nData = response.consume(dataForTag: 0x71) else {
                return nil
            }

            version = vData
            name = nData

            if let cData = response.consume(dataForTag: 0x74),
                let rawAlgo = response.consume(dataForTag: 0x7b)?.first,
                let algo = YKAlgorithm(rawValue: rawAlgo) {
                challenge = cData
                algorithm = algo
            } else {
                challenge = nil
                algorithm = nil
            }


            let idKey = Data([0xfa, 0xfa, 0xfe, 0x0d])
            let id = name.hmac(withKey: idKey, using: .SHA1)
            identifier = "ykey" + id.hexString()
        }

    }
}
