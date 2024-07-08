//
//  YKCalculateAll.swift
//  ykoath
//
//  Created on 11.07.2018.
//  Copyright © 2018 https://github.com/idf3d. All rights reserved.
//

import Foundation

class YKCalculateAll {
    class Request {
        let data: Data

        init() {
            let packet = YKPacket(.challenge, data: Data.timeChallenge())
            let apdu = APDU(.calculateAll, p1: 0x0, p2: 0x01, data: packet.packetData)
            data = apdu.packetData
        }
    }

    class Response {
        let codes: [YKCredential]
        let error: YKError?

        init(_ response: APDUResponse) {
            var result = [YKCredential]()
            self.error = response.error

            while let name = response.consume(dataForTag: 0x71) {
                guard var codeData = response.consume(dataForTag: 0x76) else {
                    _ = response.consume(dataForTag: 0x77)
                    _ = response.consume(dataForTag: 0x7c)
                    _ = response.consume(dataForTag: 0x75)

                    continue
                }

                let codeLen = Int(codeData.removeFirst())

                let code = codeData.withUnsafeBytes { ptr -> Int in
                    let typed = ptr.bindMemory(to: UInt32.self)
                    return Int(CFSwapInt32BigToHost(typed[0]))
                }

                guard let nameString = String(bytes: name, encoding: .utf8) else {
                    print("Name not parsd?!")
                    continue
                }
                let cred = YKCredential(label: nameString, type: .totp, code: code, codeLen: codeLen)
                if cred.code != nil {
                    result.append(cred)
                }
            }

            codes = result
        }

        convenience init?(_ data: Data) {
            let response = APDUResponse(data)

            guard response.success else {
                print ("Implement HaveMoreData!")
                return nil
            }

            self.init(response)
        }
    }
}
