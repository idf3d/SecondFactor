//
//  DeleteItemViewController.swift
//  ykoath
//
//  Created on 08.08.2018.
//  Copyright © 2018 https://github.com/idf3d. All rights reserved.
//

import Foundation
import Cocoa

class DeleteItemViewController: NSViewController {
    @IBOutlet weak var itemDescrFld: NSTextField!
    @IBOutlet weak var deleteBtn: NSButton!
    @IBOutlet weak var cancelBtn: NSButton!
    @IBOutlet weak var spinner: NSProgressIndicator!

    var item: YKCredential? = nil
    var deleteAction: (()->Void)? = nil

    class func instance() -> DeleteItemViewController {
        let st = NSStoryboard(name: "Main", bundle: nil)
        let vc = st.instantiateController(withIdentifier: "DeleteItemViewController") as! DeleteItemViewController
        vc.preferredContentSize = NSSize(width: vc.view.frame.width, height: vc.view.frame.height)
        return vc
    }

    override func viewWillAppear() {
        let acc = item?.account ?? "-"
        let svc = item?.issuer ?? "-"
        let str = String(format: itemDescrFld.stringValue, svc, acc)
        itemDescrFld.stringValue = str
    }

    @IBAction func delete(_ sender: Any) {
        self.dismiss(nil)
        self.deleteAction?()
    }
}
