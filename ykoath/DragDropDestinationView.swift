//
//  DragDropDestinationView.swift
//  ykoath
//
//  Created on 13.07.2018.
//  Copyright © 2018 https://github.com/idf3d. All rights reserved.
//

import Cocoa

class DragDropDestinationView: NSBox {
    var handler: ((String?)->Void)? = nil

    var isReceivingDrag = false {
        didSet {
            needsDisplay = true
        }
    }

    override func awakeFromNib() {
        super.awakeFromNib()
        self.registerForDraggedTypes([.fileURL])
    }

    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)

        guard isReceivingDrag else {
            return
        }

        NSColor.selectedControlColor.set()

        let path = NSBezierPath(rect: bounds)
        path.lineWidth = 2 // Appearance.lineWidth
        path.stroke()
    }

    override func prepareForDragOperation(_ sender: NSDraggingInfo) -> Bool {
        let pBoard = sender.draggingPasteboard
        return pBoard.canReadObject(forClasses: [NSURL.self], options: nil)
    }

    override func draggingEntered(_ sender: NSDraggingInfo) -> NSDragOperation {
        let allow = prepareForDragOperation(sender)
        isReceivingDrag = allow
        if allow {
            return .copy
        } else {
            return NSDragOperation()
        }
    }

    override func draggingExited(_ sender: NSDraggingInfo?) {
        isReceivingDrag = false
    }

    override func performDragOperation(_ sender: NSDraggingInfo) -> Bool {
        isReceivingDrag = false

        guard let handler = handler else {
            return false
        }

        if let urls = sender.draggingPasteboard.readObjects(forClasses: [NSURL.self], options: nil) {

            if let qrUrl = urls.first as? URL {
                QRDetector.detect(qrUrl, completion: handler)
                return true
            }
        }

        return false
    }
}
