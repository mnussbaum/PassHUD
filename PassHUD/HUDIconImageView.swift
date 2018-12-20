//
//  HUDIconImageView.swift
//  PassHUD
//
//  Created by Nussbaum, Michael on 12/19/18.
//  Copyright © 2018 mnussbaum. All rights reserved.
//

import Cocoa
import os

class HUDIconImageView: NSImageView {
    override func draw(_ dirtyRect: NSRect) {
        if let imageLayer = self.layer {
            imageLayer.cornerRadius =  self.frame.width / 6.0
            imageLayer.masksToBounds = true
        }  else {
            os_log(
                "Error, missing expected icon image view layer",
                log: logger,
                type: .error
            )
        }

        super.draw(dirtyRect)
    }
}
