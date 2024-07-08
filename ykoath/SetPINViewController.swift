//
//  SetPINViewController.swift
//  ykoath
//
//  Created on 22.08.2018.
//  Copyright © 2018 https://github.com/idf3d. All rights reserved.
//

import Cocoa

class SetPINViewController: NSViewController {

    @IBOutlet weak var currentPinInput: NSSecureTextField!
    @IBOutlet weak var newPinInput: NSSecureTextField!
    @IBOutlet weak var verifyPinInput: NSSecureTextField!

    @IBOutlet weak var incorrectPinLabel: NSTextField!
    @IBOutlet weak var unmatchedPinLabel: NSTextField!

    @IBOutlet weak var spinner: NSProgressIndicator!

    @IBOutlet weak var okBtn: NSButton!
    @IBOutlet weak var cancelBtn: NSButton!

    @IBOutlet weak var saveInKeychainBtn: NSButton!
    @IBOutlet weak var removePinBtn: NSButton!

    private var device: YKDevice? = nil

    override func viewWillAppear() {
        self.view.window?.styleMask.remove(.resizable)
        enabledAll(false)
        cancelBtn.isEnabled = true
        incorrectPinLabel.isHidden = true
        unmatchedPinLabel.isHidden = true
        removePinBtn.state = .off

        restoreKeychainBtnState()
    }

    override func viewDidAppear() {
        super.viewDidAppear()
        DispatchQueue.main.asyncAfter(deadline: .now()+0.3) {
            self.start()
        }
    }

    override func viewWillDisappear() {
        super.viewWillDisappear()
        self.device = nil
    }

    @IBAction func changePin(_ sender: Any) {
        unmatchedPinLabel.isHidden = true
        incorrectPinLabel.isHidden = true

        guard removePinBtn.state == .off else {
            let pin = currentPinInput.stringValue

            self.enabledAll(false)
            self.removePin(pin)
            return
        }

        let currentPIN: String?

        if currentPinInput.isEnabled {
            currentPIN = currentPinInput.stringValue
        } else {
            currentPIN = nil
        }

        let newPin = newPinInput.stringValue

        if newPin.count < 4 {
            showMessage("PIN should have at least 4 characters")
            return
        }

        guard newPin == verifyPinInput.stringValue else {
            unmatchedPinLabel.isHidden = false
            newPinInput.stringValue = ""
            verifyPinInput.stringValue = ""
            return
        }

        enabledAll(false)
        setPin(currentPIN, newPin: newPin)
    }

    @IBAction func removePin(_ sender: NSButton) {
        let enabled = sender.state == .off

        if !enabled {
            newPinInput.stringValue = ""
            verifyPinInput.stringValue = ""
            saveInKeychainBtn.state = .off
        } else {
            restoreKeychainBtnState()
        }

        newPinInput.isEnabled = enabled
        verifyPinInput.isEnabled = enabled
        saveInKeychainBtn.isEnabled = enabled
        currentPinInput.becomeFirstResponder()
    }

    @IBAction func saveInKeychain(_ sender: NSButton) {
        let isSave = sender.state == .on
        UserDefaults.standard.set(isSave, forKey: kUserDefaultsSaveInKC)
    }

    private func start() {
        perform { (dev) in
            let validation = dev.isValidationEnabled ?? false
            self.enabledAll(true, havePIN: validation)
        }
    }

    private func removePin(_ currentPin: String) {
        self.authenticate(currentPin) { (dev) in
            dev.cleanKey(completion: { (error) in
                if let error = error {
                    self.showError(error)
                    return
                } else {
                    if let id = dev.identifier {
                        let kcItem = KeychainItem(id)
                        try? kcItem.remove()
                    }
                    self.closeWindow()
                }
            })
        }
    }

    private func setPin(_ currentPin: String?, newPin: String) {
        let action: (YKDevice) -> Void = { (dev) in
            guard let key = dev.derive(newPin) else {
                self.showError(YKDeviceError.unexpected)
                return
            }

            dev.setKey(key, completion: { (error) in
                if let error = error {
                    self.showError(error)
                } else {

                    if let id = dev.identifier {
                        let kcItem = KeychainItem(id)
                        let q = DispatchQueue.main
                        q.sync {
                            let useKc = self.saveInKeychainBtn.state == .on
                            if useKc {
                                try? kcItem.save(key)
                            } else {
                                try? kcItem.remove()
                            }
                        }
                    }
                    self.closeWindow()
                }
            })
        }

        if let pin = currentPin {
            authenticate(pin, completion: action)
        } else {
            perform(action)
        }
    }

    private func perform(_ action: @escaping (YKDevice)->Void) {
        YKDevice.first { (dev, error) in
            guard let dev = dev else {
                self.showError(error ?? YKDeviceError.noSlot)
                return
            }
            self.device = dev
            action(dev)
        }
    }

    private func authenticate(_ pin: String, completion: @escaping (YKDevice)->Void) {
        perform { (dev) in
            guard let key = dev.derive(pin) else {
                self.showError(YKDeviceError.unexpected)
                return
            }

            dev.validate(key, completion: { (error) in
                if let _ = error as? YKError {
                    self.wrongPIN()
                    return
                }

                if let error = error {
                    self.showError(error)
                    return
                }

                completion(dev)
            })
        }
    }

    private func showMessage(_ msg: String) {
        guard Thread.isMainThread else {
            DispatchQueue.main.async {
                self.showMessage(msg)
            }
            return
        }

        let alert = NSAlert()
        alert.messageText = msg
        alert.alertStyle = .warning
        alert.runModal()
    }

    private func showError(_ error: Error) {
        guard Thread.isMainThread else {
            DispatchQueue.main.async {
                self.showError(error)
            }
            return
        }

        let mQueue = DispatchQueue.main
        mQueue.asyncAfter(deadline: .now() + 0.3) {
            self.view.window?.close()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                ErrorViewController.show(error)
            }
        }
    }

    private func closeWindow() {
        guard Thread.isMainThread else {
            DispatchQueue.main.async {
                self.closeWindow()
            }
            return
        }
        self.view.window?.close()
    }

    private func wrongPIN() {
        DispatchQueue.main.async {
            let validation = self.device?.isValidationEnabled ?? false

            self.enabledAll(true, havePIN: validation)
            self.incorrectPinLabel.isHidden = false
        }
    }

    private func enabledAll(_ enabled: Bool, havePIN: Bool = true) {
        guard Thread.isMainThread else {
            DispatchQueue.main.async {
                self.enabledAll(enabled, havePIN: havePIN)
            }
            return
        }

        currentPinInput.isEnabled = enabled
        newPinInput.isEnabled = enabled
        verifyPinInput.isEnabled = enabled
        okBtn.isEnabled = enabled
        saveInKeychainBtn.isEnabled = enabled
        removePinBtn.isEnabled = enabled
        cancelBtn.isEnabled = enabled
        if enabled {
            spinner.stopAnimation(nil)
            self.device = nil
            if !havePIN {
                currentPinInput.isEnabled = false
                removePinBtn.isEnabled = false
                removePinBtn.state = .off
                newPinInput.becomeFirstResponder()
            } else {
                currentPinInput.becomeFirstResponder()
            }

            removePin(removePinBtn)
        } else {
            spinner.startAnimation(nil)
        }
    }

    private func restoreKeychainBtnState() {
        guard Thread.isMainThread else {
            DispatchQueue.main.async {
                self.restoreKeychainBtnState()
            }
            return
        }

        let isSave = UserDefaults.standard.bool(forKey: kUserDefaultsSaveInKC)
        if isSave {
            saveInKeychainBtn.state = .on
        } else {
            saveInKeychainBtn.state = .off
        }
    }
}
