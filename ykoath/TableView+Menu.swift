//
//  TableView+Menu.swift
//  ykoath
//
//  Created on 08.08.2018.
//  Copyright © 2018 https://github.com/idf3d. All rights reserved.
//

import Foundation
import Cocoa

protocol DFTableViewMenuDelegate {
    func tableView(_ tableView: NSTableView, menuForRow: Int) -> NSMenu?
}

class DFTableView: NSTableView {
    open override func menu(for event: NSEvent) -> NSMenu? {
        let location = self.convert(event.locationInWindow, from: nil)
        let row = self.row(at: location)

        guard row >= 0, event.type == .rightMouseDown else {
            return super.menu(for: event)
        }

        if let d = self.delegate as? DFTableViewMenuDelegate {
            if !self.isRowSelected(row) {
                self.selectRowIndexes(IndexSet(integer: row), byExtendingSelection: false)
            }

            return d.tableView(self, menuForRow: row)
        }

        return super.menu(for: event)
    }
}

final class Action: NSObject {

    private let _action: () -> ()

    init(action: @escaping () -> ()) {
        _action = action
        super.init()
    }

    @objc
    func action() {
        _action()
    }

    func menuItem(title: String, keyEquivalent: String) -> NSMenuItem {
        let item = NSMenuItem(title: title, action: #selector(action), keyEquivalent: keyEquivalent)
        item.representedObject = self
        item.target = self
        return item
    }

}
