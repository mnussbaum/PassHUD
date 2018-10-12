//
//  HUDView.swift
//  pass-hud
//
//  Created by Nussbaum, Michael on 10/12/18.
//  Copyright © 2018 mnussbaum. All rights reserved.
//

import Cocoa

class HUDView: NSView {
    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
        self.appearance = NSAppearance(named: .vibrantDark)
    }
    
    override var allowsVibrancy: Bool { return true }
}
