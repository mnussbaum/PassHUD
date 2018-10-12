//
//  AppDelegate.swift
//  pass-hud
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

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        if let button = statusItem.button {
            button.image = NSImage(named:NSImage.Name("StatusBarButtonImage"))
            button.action = #selector(activateHUD(_:))
        }
        
        self.hudWindow.setAppearance()
        self.hudWindow.contentViewController = HUDViewController.create()
        
        HotKey.register(UInt32(kVK_ANSI_Slash), modifiers: UInt32(cmdKey), block: {
            self.activateHUD(nil)
        })
    }

    @objc func activateHUD(_ sender: Any?) {
        self.hudWindow.center()
        self.hudWindow.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
        
    }

    func applicationWillTerminate(_ aNotification: Notification) {
        // TODO: unregister hotkey
    }


}

