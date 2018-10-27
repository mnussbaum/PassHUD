//
//  HUDTableCellView.swift
//  PassHUD
//
//  Created by Nussbaum, Michael on 10/22/18.
//  Copyright © 2018 mnussbaum. All rights reserved.
//

import Cocoa

class HUDTableCellView: NSTableCellView {

    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
    }

    override var backgroundStyle: NSView.BackgroundStyle {
        set {
            if let rowView = self.superview as? NSTableRowView {
                rowView.isEmphasized = true
            } else {
                super.backgroundStyle = newValue
            }
        }
        get {
            return super.backgroundStyle;
        }
    }
}
