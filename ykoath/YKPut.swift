//
//  YKPut.swift
//  ykoath
//
//  Created on 18.07.2018.
//  Copyright © 2018 https://github.com/idf3d. All rights reserved.
//

import Foundation

class YKPut {
    class Request {
        let data: Data

        init?(_ credential: YKCredential) {
            guard let name = credential.ykLabel.data(using: .utf8),
                name.count < 64,
                name.count > 0,
                let key = credential.secret,
                let algorithm = credential.algorithm
                else {
                    return nil
            }

            let p1 = YKPacket(.name, data: name)

            let keyAlgo = algorithm.rawValue + credential.type.rawValue
            var kData = Data([keyAlgo, UInt8(credential.digits)])
            kData.append(key)

            let p2 = YKPacket(.key, data: kData)

            var apduData = Data()
            apduData.append(p1.packetData)
            apduData.append(p2.packetData)

            let apdu = APDU(.put, p1: 0x00, p2: 0x00, data: apduData)

            data = apdu.packetData
        }
    }
}
