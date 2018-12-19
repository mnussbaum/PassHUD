//
//  NSImage.swift
//  PassHUD
//
//  Created by Nussbaum, Michael on 12/18/18.
//  Copyright © 2018 mnussbaum. All rights reserved.
//

import Cocoa

// Based off of https://gist.github.com/usagimaru/c0a03ef86b5829fb9976b650ec2f1bf4

extension NSImage {
    func copyWithTint(color: NSColor) -> NSImage {
        let image = self.copy() as! NSImage

        image.lockFocus()
        color.set()
        NSRect(
            origin: NSZeroPoint,
            size: image.size
        ).fill(using: .sourceAtop)
        image.isTemplate = false
        image.unlockFocus()

        return image
    }
}
