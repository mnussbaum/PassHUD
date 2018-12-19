//
//  NSString.swift
//  PassHUD
//
//  Created by Nussbaum, Michael on 12/18/18.
//  Copyright © 2018 mnussbaum. All rights reserved.
//

import Cocoa

// Based off of:
//  * https://stackoverflow.com/questions/35882103/hash-value-of-string-that-would-be-stable-across-ios-releases
//  * https://stackoverflow.com/questions/11120840/hash-string-into-rgb-color

extension String {
    func hashCode() -> UInt64 {
        var result = UInt64 (5381)
        let buf = [UInt8](self.utf8)
        for b in buf {
            result = 127 * (result & 0x00FFFFFFFFFFFFFF) + UInt64(b)
        }

        return result
    }

    func toRGB() -> NSColor {
        let hash = self.hashCode()
        var red = max(CGFloat((hash & 0xFF0000) >> 16) / 255.0, 0.01)
        var green = max(CGFloat((hash & 0x00FF00) >> 8) / 255.0, 0.01)
        var blue = max(CGFloat(hash & 0x0000FF) / 255.0, 0.01)

        // Ensure a minimum luminance
        // https://en.wikipedia.org/wiki/Relative_luminance
        while (0.2126 * red + 0.7152 * green + 0.0722 * blue) <= 0.5 {
            blue = min(blue * 2, 1.0)
            red = min(red * 2, 1.0)
            green = min(green * 2, 1.0)
        }

        // Attempt to avoid browns from close color combos,
        // without boosting one color too much
        while abs(blue - red) < 0.2 {
            red = min(red + 0.1, 1.0)
            blue = max(blue - 0.1, 0)
        }
        while abs(green - red) < 0.2 {
            green = min(green + 0.1, 1.0)
            red = max(red - 0.1, 0)
        }
        while abs(blue - green) < 0.2 {
            blue = min(blue + 0.1, 1.0)
            green = max(green - 0.1, 0)
        }

        return NSColor(
            red: red,
            green: green,
            blue: blue,
            alpha: CGFloat(1.0)
        )
    }
}
