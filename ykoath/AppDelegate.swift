//
//  AppDelegate.swift
//  ykoath
//
//  Created on 09.07.2018.
//  Copyright © 2018 https://github.com/idf3d. All rights reserved.
//

import Cocoa

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {

    func applicationDidFinishLaunching(_ aNotification: Notification) {
    }

    func applicationWillTerminate(_ aNotification: Notification) {
    }

    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {

        // do nothing if we have visible windows
        if flag {
            return true
        }

        guard let window = mainWindow()?.window else {
            return false
        }

        if flag {
            window.orderFront(self)
        } else {
            window.makeKeyAndOrderFront(self)
        }
        return true
    }

    private func mainWindow() -> NSWindowController? {
        let st = NSStoryboard.main

        guard let controller = st?.instantiateInitialController() as? NSWindowController else {
            return nil
        }

        return controller
    }
}

