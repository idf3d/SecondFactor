//
//  DeviceWaiterViewController.swift
//  ykoath
//
//  Created on 15.08.2018.
//  Copyright © 2018 https://github.com/idf3d. All rights reserved.
//

import Foundation
import Cocoa
import CryptoTokenKit

class DeviceWaiterViewController: NSViewController {

    @IBOutlet weak var spinner: NSProgressIndicator!
    var action: ((YKDevice)->Void)? = nil

    class func instance() -> DeviceWaiterViewController {
        let st = NSStoryboard(name: "Main", bundle: nil)
        let vc = st.instantiateController(withIdentifier: "DeviceWaiterViewController") as! DeviceWaiterViewController
        vc.preferredContentSize = NSSize(width: vc.view.frame.width, height: vc.view.frame.height)
        return vc
    }

    override func viewWillAppear() {
        spinner.startAnimation(self)
        let kPath = #keyPath(TKSmartCardSlotManager.slotNames)
        TKSmartCardSlotManager.default?.addObserver(self, forKeyPath: kPath, options: [.new], context: nil)
    }

    @IBAction func cancel(_ sender: Any) {
        self.dismiss(sender)
        DispatchQueue.main.asyncAfter(deadline: .now()+0.2) {
            NSApp.terminate(sender)
        }
    }

    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        YKDevice.first { (dev, error) in
            guard let dev = dev else {
                return
            }
            DispatchQueue.main.async {
                self.action?(dev)
            }
        }
    }

}
