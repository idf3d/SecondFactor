//
//  URL.swift
//  ykoath
//
//  Created on 14.07.2018.
//  Copyright © 2018 https://github.com/idf3d. All rights reserved.
//

import Foundation

extension URL {
    var parameters: [String: String] {
        var result = [String:String]()

        guard let components = URLComponents(url: self, resolvingAgainstBaseURL: true),
            let items = components.queryItems else {
            return result
        }

        for item in items {
            result[item.name.lowercased()] = item.value
        }

        return result
    }
}
