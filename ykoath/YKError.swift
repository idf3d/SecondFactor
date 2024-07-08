//
//  YKError.swift
//  ykoath
//
//  Created on 26.07.2018.
//  Copyright © 2018 https://github.com/idf3d. All rights reserved.
//

import Foundation

enum YKError: Error {
    case InputError
    case WrongSyntax
    case Generic
    case AuthRequired
    case NoSpace
    case Unknown

    init (_ code: UInt16) {
        switch code {
        case 0x6984:
            // No such object or Authorisation not enbaled
            self = .InputError
        case 0x6a80:
            self = .WrongSyntax
        case 0x6a84:
            self = .NoSpace
        case 0x6581:
            self = .Generic
        case 0x6982:
            self = .AuthRequired
        default:
            self = .Unknown
        }
    }
    
}
