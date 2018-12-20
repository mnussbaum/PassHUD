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

    let defaultHotKey = HotKeyConfig(modifiers: ["cmd"], key: "/")

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        if let button = statusItem.button {
            button.image = NSImage(named:NSImage.Name("PadLockStatusBarButtonImage"))
            button.action = #selector(toggleHUD(_:))
        }
        self.hudWindow.setAppearance()

        let config = ConfigParser.ParseConfig()
        self.hudViewController = HUDViewController.create(
            config: config
        )
        self.hudWindow.contentViewController = self.hudViewController

        self.registerHotKeys(config)
    }

    @objc func toggleHUD(_ sender: Any?) {
        self.hudViewController?.toggle(sender)
    }

    func registerHotKeys(_ config: Config?) {
        for hotKey in config?.hotKeys ?? [defaultHotKey] {
            HotKey.register(
                HotKeyParser.charToKeyCode(hotKey.key),
                modifiers: HotKeyParser.modifiersToModCode(hotKey.modifiers),
                block: {
                    self.toggleHUD(nil)
                }
            )
        }
    }
}
