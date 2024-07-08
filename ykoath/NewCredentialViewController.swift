//
//  NewCredentialViewController.swift
//  ykoath
//
//  Created on 09.08.2018.
//  Copyright © 2018 https://github.com/idf3d. All rights reserved.
//

import Foundation
import Cocoa

extension NSNotification.Name {
    public static let YKNewCredentialAdded: NSNotification.Name = NSNotification.Name(rawValue: "net.dflab.YKNewCredentialAdded" )
}

enum QRCredError: Error {
    case NotFound
    case Invalid
}

class NewCredentialViewController: NSViewController {
    @IBOutlet weak var dragDropDestination: DragDropDestinationView!

    override func viewWillAppear() {
        dragDropDestination.handler = { [weak self] str in
            self?.detectionCompleted(str)
        }
    }

    @IBAction func scanScreen(_ sender: Any) {
        QRDetector.detectFromScreens { [weak self] str in
            self?.detectionCompleted(str)
        }
    }

    func detectionCompleted(_ str: String?) {
        guard let str = str else {
            ErrorViewController.show(QRCredError.NotFound)
            return
        }

        guard let cred = YKCredential(withString: str) else {
            ErrorViewController.show(QRCredError.Invalid)
            return
        }

        addCred(cred)
    }

    private func addCred(_ cred: YKCredential) {
        let addAction: (AuthManager)->Void = { manager in
            if let error = manager.error,
                case PasswordViewController.UIError.cancelled = error {
                DispatchQueue.main.async {
                    self.view.window?.close()
                }
                return
            }
            manager.device.put(cred, completion: { (error) in
                if manager.handler()(error) {
                    return
                }

                if let error = error {
                    ErrorViewController.show(error)
                } else {
                    self.onCredAdded(cred)
                }
            })
        }

        YKDevice.first { (dev, error) in
            if let error = error {
                ErrorViewController.show(error)
                return
            }

            guard let dev = dev else {
                ErrorViewController.show(YKDeviceError.noSlot)
                return
            }

            let manager = AuthManager(device: dev, parent: self, action: addAction)
            addAction(manager)
        }
    }

    private func onCredAdded(_ cred: YKCredential) {
        guard Thread.isMainThread else {
            DispatchQueue.main.async {
                self.onCredAdded(cred)
            }
            return
        }

        let name = NSNotification.Name.YKNewCredentialAdded

        NotificationCenter.default.post(name: name, object: self, userInfo: ["addedCredential": cred])

        // now close our window
        self.view.window?.close()
    }
}
