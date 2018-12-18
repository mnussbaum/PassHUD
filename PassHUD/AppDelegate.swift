//
//  AppDelegate.swift
//  PassHUD
//
//  Created by Nussbaum, Michael on 10/10/18.
//  Copyright © 2018 mnussbaum. All rights reserved.
//

import Cocoa
import Carbon
import os

let logger = OSLog(
    subsystem: Bundle.main.bundleIdentifier!,
    category: "HUD"
)

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {
    let statusItem = NSStatusBar
        .system
        .statusItem(withLength: NSStatusItem.squareLength)
    let hudWindow = HUDWindow()
    var hudViewController: HUDViewController?

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        if let button = statusItem.button {
            button.image = NSImage(named:NSImage.Name("PadLockStatusBarButtonImage"))
            button.action = #selector(toggleHUD(_:))
        }
        self.hudWindow.setAppearance()
        self.hudViewController = HUDViewController.create(
            config: ConfigParser.ParseConfig()
        )
        self.hudWindow.contentViewController = self.hudViewController

        HotKey.register(UInt32(kVK_ANSI_Slash), modifiers: UInt32(cmdKey), block: {
            self.toggleHUD(nil)
        })
    }

    @objc func toggleHUD(_ sender: Any?) {
        self.hudViewController?.toggle(sender)
    }
}
