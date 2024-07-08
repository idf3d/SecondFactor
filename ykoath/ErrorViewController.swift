//
//  ErrorViewController.swift
//  ykoath
//
//  Created on 19.08.2018.
//  Copyright © 2018 https://github.com/idf3d. All rights reserved.
//

import Foundation
import Cocoa

class ErrorViewController: NSAlert {
    class func show(_ error: Error) {
        if !Thread.isMainThread {
            DispatchQueue.main.async {
                ErrorViewController.show(error)
            }
            return
        }

        let instance = ErrorViewController(error: error)
        instance.runModal()
    }

    init(error: Error) {
        super.init()

        if let error = error as? YKError {
            self.setup(error)
            return
        }

        if let error = error as? YKDeviceError {
            self.setup(error)
            return
        }

        if let error = error as? QRCredError {
            self.setup(error)
            return
        }

        self.setupAsUnexpected()
    }

    private func setup(_ error: YKError) {
        let msg: String
        let info: String

        switch error {
        case .AuthRequired:
            msg = "Authentication required"
            info = "Device authentication was requested, but not performed."
        case .Generic:
            msg = "Generic error"
            info = ""
        case .InputError:
            msg = "Invalid parameter"
            info = "Parameter provided in request was not valid."
        case .NoSpace:
            msg = "No space left"
            info = ""
        case .Unknown:
            msg = "Unknown error"
            info = "Request was performed, but error reported by device is not known for application."
        case .WrongSyntax:
            msg = "Wrong syntax"
            info = ""
        }

        self.messageText = msg
        self.informativeText = info
    }

    private func setup(_ error: YKDeviceError) {
        let msg: String
        let info: String

        switch error {
        case .appSelectFailed:
            msg = "Unsupported device"
            info = "Device was identified as Yubikey, but responded unexpectedly. Is it supports CCID mode?"
        case .invalidDevice:
            msg = "Device not valid"
            info = "Device malfunction, removed or compromised."
        case .noDevice:
            msg = "Device not found"
            info = "Slot was found, but device is not present, or not supports CCID mode"
        case .noSlot:
            msg = "Device not found"
            info = "Yubikey not inserted, or not supports CCID mode (refer Yubikey documentation)"
        case .unexpected:
            msg = "Device communication error"
            info = "Unexpected error."
        case .wrongInput:
            msg = "Wrong input"
            info = "Input data was not correct."
        case .validationNotEnabled:
            msg = "Validation not enabled"
            info = "Application tried to perform mutual validation, but it is not enabled on device."
        }

        self.messageText = msg
        self.informativeText = info
    }

    private func setup(_ error: QRCredError) {
        let msg: String
        let info: String

        switch error {
        case .NotFound:
            msg = "QR Code not found"
            info = "Provided image does not contain visible QR code"
        case .Invalid:
            msg = "Invalid input"
            info = "QR code was recognised, although it doesn't contain valid key information"
        }

        self.messageText = msg
        self.informativeText = info
    }

    private func setupAsUnexpected() {
        self.messageText = "Unexpected error."
        self.informativeText = "Try to restart application. Check if Yubikey is properly inserted and supports CCID mode."
    }
}
