//
//  YKSetCode.swift
//  ykoath
//
//  Created on 01.08.2018.
//  Copyright © 2018 https://github.com/idf3d. All rights reserved.
//

import Foundation

class YKSetCode {
    class Request {
        let data: Data

        init?(removeCode: Bool) {
            guard removeCode else {
                return nil
            }

            let emptyKey = YKPacket(.key, data: Data())
            let apdu = APDU(.setCode, p1: 0x00, p2: 0x00, data: emptyKey.packetData)
            data = apdu.packetData
        }

        init(_ key: YKDerivedKey, algo: YKAlgorithm) {
            let ourChallenge = Data.random(length: 8)
            let ourReply = ourChallenge.hmac(withKey: key.keyData, using: CryptoAlgorithm(ykAlgo: algo))

            var kData = Data([algo.rawValue])
            kData.append(key.keyData)

            let keyPacket = YKPacket(.key, data: kData)

            let challengePacket = YKPacket(.challenge, data: ourChallenge)
            let replyPacket = YKPacket(.challengeResponse, data: ourReply)

            var request = Data()
            request.append(keyPacket.packetData)
            request.append(challengePacket.packetData)
            request.append(replyPacket.packetData)

            let apdu = APDU(.setCode, p1: 0x00, p2: 0x00, data: request)

            data = apdu.packetData
        }
    }
}
