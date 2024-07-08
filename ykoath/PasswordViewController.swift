//
//  PasswordViewController.swift
//  ykoath
//
//  Created on 30.07.2018.
//  Copyright © 2018 https://github.com/idf3d. All rights reserved.
//

import Foundation
import Cocoa

let kUserDefaultsSaveInKC = "PasswordControllerSaveInKeyChain"

class PasswordViewController: NSViewController {
    var completion: ((Error?)->Void)? = nil
    var device: YKDevice? = nil

    @IBOutlet weak var saveInKeychainBtn: NSButton!
    @IBOutlet weak var incorrectPinLabel: NSTextField!

    @IBOutlet weak var secureField: NSSecureTextField!
    @IBOutlet weak var spinner: NSProgressIndicator!
    @IBOutlet weak var okBtn: NSButton!

    enum UIError: Error {
        case cancelled
    }

    override func viewWillAppear() {
        incorrectPinLabel.isHidden = true
        let isSave = UserDefaults.standard.bool(forKey: kUserDefaultsSaveInKC)
        if isSave {
            saveInKeychainBtn.state = .on
        } else {
            saveInKeychainBtn.state = .off
        }
    }

    @IBAction func ok(_ sender: Any) {
        let pwd = secureField.stringValue
        okBtn.isEnabled = false
        secureField.isEnabled = false
        saveInKeychainBtn.isEnabled = false
        incorrectPinLabel.isHidden = true
        spinner.startAnimation(sender)

        let shouldSave = saveInKeychainBtn.state == .on
        UserDefaults.standard.set(shouldSave, forKey: kUserDefaultsSaveInKC)

        guard let dev = self.device else {
            self.complete(YKDeviceError.noDevice)
            return
        }

        guard let key = dev.derive(pwd) else {
            self.complete(YKDeviceError.invalidDevice)
            return
        }

        dev.validate(key) { (error) in
            if let error = error {
                if let ykError = error as? YKError,
                    ykError == YKError.WrongSyntax {
                    self.retryPassword()
                    return
                }

                self.complete(error)
                return
            }

            if shouldSave, let id = dev.identifier {
                let c = KeychainItem(id)
                do {
                    try c.save(key)
                } catch {
                    print("Save to keychain was failed.")
                }
            }

            self.complete(nil)
        }
    }

    @IBAction func cancel(_ sender: Any) {
        self.complete(UIError.cancelled)
    }

    private func retryPassword() {
        if !Thread.isMainThread {
            DispatchQueue.main.async {
                self.retryPassword()
            }
            return
        }

        self.okBtn.isEnabled = true
        self.secureField.isEnabled = true
        self.saveInKeychainBtn.isEnabled = true
        self.spinner.stopAnimation(nil)
        self.incorrectPinLabel.isHidden = false
    }

    private func complete(_ err: Error?) {
        if !Thread.isMainThread {
            DispatchQueue.main.async {
                self.complete(err)
            }
            return
        }

        self.completion?(err)
        self.dismiss(nil)
    }
}

extension PasswordViewController {
    class func instance() -> PasswordViewController {
        let st = NSStoryboard(name: "Main", bundle: nil)
        let vc = st.instantiateController(withIdentifier: "PasswordViewController") as! PasswordViewController
        vc.preferredContentSize = NSSize(width: vc.view.frame.width, height: vc.view.frame.height)
        return vc
    }
}
