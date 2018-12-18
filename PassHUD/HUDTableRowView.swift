//
//  HUDTableRowView.swift
//  PassHUD
//
//  Created by Nussbaum, Michael on 11/12/18.
//  Copyright © 2018 mnussbaum. All rights reserved.
//

import Cocoa
import os

class HUDTableRowView: NSTableRowView {
    weak var parentTableView: NSTableView?
    var index: Int?
    var trackingArea: NSTrackingArea?

    override func updateTrackingAreas() {
        super.updateTrackingAreas()
        self.ensureTrackingArea()
        if !trackingAreas.contains(self.trackingArea!) {
            self.addTrackingArea(self.trackingArea!)
        }
    }

    func ensureTrackingArea() {
        if self.trackingArea != nil {
            return
        }

        self.trackingArea = NSTrackingArea(
            rect: NSZeroRect,
            options: [
                .inVisibleRect,
                .activeInActiveApp,
                .mouseEnteredAndExited
            ],
            owner: self,
            userInfo: nil
        )
    }

    override func mouseEntered(with event: NSEvent) {
        guard let index = self.index else {
            os_log(
                "Error, missing row index from HUDTableRowView",
                log: logger,
                type: .error
            )
            return
        }
        guard let parentTableView = self.parentTableView else {
            os_log(
                "Error, missing parent table view from HUDTableRowView",
                log: logger,
                type: .error
            )
            return
        }

        parentTableView.selectRowIndexes(
            IndexSet(integer: index),
            byExtendingSelection: false
        )
    }
}
