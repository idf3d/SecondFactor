//
//  ViewController.swift
//  ykoath
//
//  Created on 09.07.2018.
//  Copyright © 2018 https://github.com/idf3d. All rights reserved.
//

import Cocoa

class ViewController: NSViewController, NSTableViewDelegate, NSTableViewDataSource, DFTableViewMenuDelegate {

    var codes = [YKCredential]()
    var message: String? = nil

    @IBOutlet weak var tableView: NSTableView!
    @IBOutlet weak var indicator: NSProgressIndicator!

    var timer: Timer? = nil
    var notificationToken: NSObjectProtocol? = nil

    override func viewDidAppear() {
        generate()
        let name = NSNotification.Name.YKNewCredentialAdded
        notificationToken = NotificationCenter.default.addObserver(forName: name, object: nil, queue: nil, using: { (notification) in
            //expire all, to force re-generation
            self.indicator.doubleValue = 1
        })
    }

    override func viewWillDisappear() {
        if let token = notificationToken {
            let center = NotificationCenter.default
            center.removeObserver(token)
        }

        stopTimer()
    }

    private func runAction(_ action: @escaping (AuthManager)->Void) {
        YKDevice.first { (dev, err) in
            guard let dev = dev else {
                self.waitForDevice()
                return
            }

            let auth = AuthManager(device: dev, parent: self, action: action)
            action(auth)
        }
    }

    func generate() {
        let action: (AuthManager)->Void = { (manager) in
            if let error = manager.error,
                case PasswordViewController.UIError.cancelled = error {
                DispatchQueue.main.async {
                    self.showMessage("Password required but not provided")
                    self.view.window?.close()
                }
                return
            }
            manager.device.calculateAll({ (codes, error) in
                if manager.handler()(error) {
                    return
                }

                if let error = error {
                    self.showMessage("Error.")
                    ErrorViewController.show(error)
                    self.stopTimer()
                    return
                }

                if self.timer == nil {
                    self.startTimer()
                }

                guard let codes = codes else {
                    self.showMessage("No supported credentials found")
                    return
                }

                self.showCodes(codes)
            })
        }
        runAction(action)
    }

    func stopTimer() {
        guard Thread.isMainThread else {
            DispatchQueue.main.async {
                self.stopTimer()
            }
            return
        }
        self.indicator.doubleValue = 0
        if let timer = self.timer {
            timer.invalidate()
            self.timer = nil
        }
    }

    func startTimer() {
        DispatchQueue.main.async {
            self.stopTimer()

            self.indicator.doubleValue = 100
            self.timer = Timer.scheduledTimer(withTimeInterval: 0.3, repeats: true, block: { [weak self] (_) in
                DispatchQueue.main.async {
                    guard let sSelf = self else {
                        return
                    }

                    guard sSelf.indicator.doubleValue > 0.1 else {
                        sSelf.indicator.doubleValue = 0
                        sSelf.stopTimer()
                        sSelf.codes.removeAll()
                        sSelf.tableView.reloadData()
                        sSelf.generate()
                        return
                    }
                    sSelf.indicator.doubleValue -= 1
                }
            })
        }
    }

    func showMessage(_ str: String) {
        DispatchQueue.main.async {
            self.message = str
            self.codes.removeAll()
            self.tableView.reloadData()
        }
    }

    func waitForDevice() {
        guard Thread.isMainThread else {
            DispatchQueue.main.async {
                self.waitForDevice()
            }
            return
        }

        let vc = DeviceWaiterViewController.instance()
        vc.action = {(_) in
            self.dismiss(vc)
            self.generate()
        }
        self.presentAsSheet(vc)
    }

    ///

    func showCodes(_ codes: [YKCredential]) {
        DispatchQueue.main.async {
            self.message = nil
            self.codes = codes
            self.tableView.reloadData()
        }
    }

    func numberOfRows(in tableView: NSTableView) -> Int {
        if message != nil {
            return 1
        } else {
            return codes.count
        }
    }

    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {

        if let message = message {
            if tableColumn == tableView.tableColumns[1] {
                return cell("AccountCell", text: message)
            } else {
                return nil
            }
        }

        guard codes.count > row else {
            return nil
        }

        let cred = codes[row]

        if tableColumn == tableView.tableColumns[0] {
            return cell("ServiceCell", text: cred.issuer ?? "")
        }

        if tableColumn == tableView.tableColumns[1] {
            return cell("AccountCell", text: cred.account)
        }

        if tableColumn == tableView.tableColumns[2] {
            return cell("CodeCell", text: cred.code ?? "")
        }

        return nil
    }

    func tableView(_ tableView: NSTableView, menuForRow: Int) -> NSMenu? {
        guard let code = codes[menuForRow].code else {
            return nil
        }

        let m = NSMenu(title: "Menu")

        let copy = Action {
            let pBoard = NSPasteboard.general
            pBoard.clearContents()
            pBoard.setString(code, forType: .string)
        }

        let item = copy.menuItem(title: "Copy", keyEquivalent: "")

        m.addItem(item)

        let deleteBlockAction: (AuthManager)-> Void = {(manager) in
            manager.device.delete(self.codes[menuForRow], completion: { (error) in
                if manager.handler()(error) {
                    return
                }

                if let error = error {
                    ErrorViewController.show(error)
                    return
                }

                if self.codes.count >= menuForRow {
                    self.codes.remove(at: menuForRow)
                    self.showCodes(self.codes)
                }
            })
        }

        let delete = Action {
            let vc = DeleteItemViewController.instance()
            vc.item = self.codes[menuForRow]
            vc.deleteAction = {
                YKDevice.first(completion: { (dev, err) in
                    if let err = err {
                        ErrorViewController.show(err)
                        return
                    }
                    guard let dev = dev else {
                        ErrorViewController.show(YKDeviceError.noSlot)
                        return
                    }

                    let manager = AuthManager(device: dev, parent: self, action: deleteBlockAction)
                    deleteBlockAction(manager)
                })
            }
            self.presentAsSheet(vc)
        }

        let item2 = delete.menuItem(title: "Delete", keyEquivalent: "")
        m.addItem(item2)

        return m
    }

    private func cell(_ id: String, text: String) -> NSView? {
        guard let cell = tableView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: id), owner: nil) as? NSTableCellView else {
            return nil
        }

        cell.textField?.stringValue = text

        return cell
    }
}
