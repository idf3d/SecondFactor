//
//  AuthManager.swift
//  ykoath
//
//  Created on 14.08.2018.
//  Copyright © 2018 https://github.com/idf3d. All rights reserved.
//

import Foundation
import Cocoa

class AuthManager {
    let device: YKDevice
    weak var parent: NSViewController?
    let action: (AuthManager)->Void
    var kcEnabled = true
    var error: Error?

    private var kcItem: KeychainItem? {
        guard kcEnabled else { return nil }
        guard let id = device.identifier else { return nil }
        return KeychainItem(id)
    }

    init(device: YKDevice, parent: NSViewController, action: @escaping (AuthManager)->Void) {
        self.device = device
        self.parent = parent
        self.action = action
    }


    func handler() -> (Error?)->Bool {
        return { (err) in
            guard let err = err as? YKError,
                err == YKError.AuthRequired else {
                    return false
            }

            if let key = self.kcItem?.key() {
                self.performAuth(key)
            } else {
                self.performUIAuth()
            }

            return true
        }
    }

    private func performAuth(_ key: YKDerivedKey) {
        device.validate(key) { (error) in
            guard error != nil else {
                self.action(self)
                return
            }

            do {
                try self.kcItem?.remove()
            } catch {
                print("AuthManager can not remove KCItem")
            }
            self.kcEnabled = false
            self.performUIAuth()
        }
    }

    private func performUIAuth() {
        guard Thread.isMainThread else {
            DispatchQueue.main.async {
                self.performUIAuth()
            }
            return
        }

        let vc = PasswordViewController.instance()
        vc.device = device
        vc.completion = { error in
            self.error = error
            self.action(self)
        }

        parent?.presentAsSheet(vc)
    }
}
