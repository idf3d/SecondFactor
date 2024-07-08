//
//  YKValidate.swift
//  ykoath
//
//  Created on 09.07.2018.
//  Copyright © 2018 https://github.com/idf3d. All rights reserved.
//

import Foundation

class YKValidate {
    class Request {
        let data: Data
        let expectedReply: Data

        init(challenge: Data, key: YKDerivedKey, algo: YKAlgorithm) {

            let ourChallenge = Data.random(length: 8)
            expectedReply = ourChallenge.hmac(withKey: key.keyData, using: CryptoAlgorithm(ykAlgo: algo))

            let reply = challenge.hmac(withKey: key.keyData, using: CryptoAlgorithm(ykAlgo: algo))

            let replyPacket = YKPacket(.challengeResponse, data: reply)
            let challengePacket = YKPacket(.challenge, data: ourChallenge)

            var d = Data()
            d.append(replyPacket.packetData)
            d.append(challengePacket.packetData)

            let apdu = APDU(.validate, p1: 0x00, p2: 0x00, data: d)
            
            data = apdu.packetData
        }
    }
}
