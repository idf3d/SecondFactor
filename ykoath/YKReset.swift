//
//  YKReset.swift
//  ykoath
//
//  Created on 10.09.2018.
//  Copyright © 2018 https://github.com/idf3d. All rights reserved.
//

import Foundation

class YKReset {
    class Request {
        let data: Data

        init?(resetDevice: Bool) {
            guard resetDevice else {
                return nil
            }

            data = Data([0x00, YKInstruction.reset.rawValue, 0xde, 0xad])
        }
    }
}
