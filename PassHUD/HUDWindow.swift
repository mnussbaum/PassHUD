//
//  HUDWindow.swift
//  PassHUD
//
//  Created by Nussbaum, Michael on 10/12/18.
//  Copyright © 2018 mnussbaum. All rights reserved.
//

import Cocoa

class HUDWindow: NSWindow {
    func setAppearance() {
        self.backgroundColor = .clear
        self.collectionBehavior = .moveToActiveSpace
        self.hidesOnDeactivate = true
        self.isMovableByWindowBackground = true
        self.styleMask.remove(.miniaturizable)
        self.styleMask.remove(.closable)
        self.styleMask.remove(.resizable)
        self.styleMask.insert(.fullSizeContentView)
        self.titlebarAppearsTransparent = true
    }
}
