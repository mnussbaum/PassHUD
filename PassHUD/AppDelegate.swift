//
//  AppDelegate.swift
//  PassHUD
//
//  Created by Nussbaum, Michael on 10/10/18.
//  Copyright © 2018 mnussbaum. All rights reserved.
//

import Cocoa
import Carbon

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {
    let statusItem = NSStatusBar
        .system
        .statusItem(withLength: NSStatusItem.squareLength)
    let hudWindow = HUDWindow()
    var hudViewController: HUDViewController?
    var hudActive = false

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        if let button = statusItem.button {
            button.image = NSImage(named:NSImage.Name("StatusBarButtonImage"))
            button.action = #selector(toggleHUD(_:))
        }
        
        self.hudWindow.setAppearance()
        self.hudViewController = HUDViewController.create()
        self.hudWindow.contentViewController = self.hudViewController
        
        HotKey.register(UInt32(kVK_ANSI_Slash), modifiers: UInt32(cmdKey), block: {
            self.toggleHUD(nil)
        })
    }

    @objc func toggleHUD(_ sender: Any?) {
        if self.hudActive {
            self.hudWindow.orderOut(sender)
            self.hudActive = false
        } else {
            NSApp.activate(ignoringOtherApps: true)
            self.hudViewController?.activate()
            self.hudActive = true
        }
    }
}
