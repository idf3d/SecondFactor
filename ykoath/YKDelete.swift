//
//  YKDelete.swift
//  ykoath
//
//  Created on 01.08.2018.
//  Copyright © 2018 https://github.com/idf3d. All rights reserved.
//

import Foundation

class YKDelete {
    class Request {
        let data: Data

        init?(_ credential: YKCredential) {
            guard let label = credential.ykLabel.data(using: .utf8) else {
                return nil
            }

            let dPacket = YKPacket(.name, data: label).packetData
            let apdu = APDU(.delete, p1: 0x00, p2: 0x00, data: dPacket)

            data = apdu.packetData
        }
    }
}
