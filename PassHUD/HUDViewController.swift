//
//  HUDViewController.swift
//  PassHUD
//
//  Created by Nussbaum, Michael on 10/11/18.
//  Copyright © 2018 mnussbaum. All rights reserved.
//

import Cocoa
import Carbon

class HUDViewController: NSViewController  {
    @IBOutlet weak var searchField: NSSearchField!
    @IBOutlet weak var searchResultsTableView: NSTableView!

    let visualEffect = NSVisualEffectView()

    var searchResults: [String] = []
    var recentSearches: Set<String> = []
    var lastPassCommandSentIndex = 0
    var lastPassCommandReceivedIndex = 0

    func activate() {
        self.view.window?.center()
        self.view.window?.makeKeyAndOrderFront(nil)
        self.searchField.stringValue = ""
        if !self.recentSearches.isEmpty {
            self.searchResults = Array(recentSearches)
            self.searchResultsTableView.reloadData()
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        self.visualEffect.blendingMode = .behindWindow
        self.visualEffect.state = .followsWindowActiveState
        self.visualEffect.material = .dark
        self.visualEffect.layer?.cornerRadius = 5.0
        self.visualEffect.frame = self.view.frame
        self.visualEffect.subviews = [self.view]
        self.view = self.visualEffect

        self.searchField.delegate = self

        self.searchResultsTableView.headerView = nil
        self.searchResultsTableView.delegate = self
        self.searchResultsTableView.dataSource = self
        self.searchResultsTableView.target = self
        self.searchResultsTableView.action = #selector(searchResultsViewClickHandler(_:))

        NSEvent.addLocalMonitorForEvents(matching: .keyDown) {
            return self.keyDown(with: $0)
        }

        // Populate initial table data
        self.runPassCommand(arguments: ["ls"])
    }

    func keyDown(with event: NSEvent) -> NSEvent? {
        if Int(event.keyCode) == kVK_Return {
            if let selectedPassword = self.selectedPassword() {
                self.recentSearches.formUnion([selectedPassword])
            }

            self.searchResultsViewClick()

            return nil
        } else if Int(event.keyCode) == kVK_DownArrow {
            if !self.isFocused(view: self.searchResultsTableView) {
                self.view
                    .window?
                    .makeFirstResponder(self.searchResultsTableView)
            }
        } else if Int(event.keyCode) == kVK_UpArrow {
            if !self.isFocused(view: self.searchResultsTableView) {
                self.view
                    .window?
                    .makeFirstResponder(self.searchResultsTableView)
            }
        } else if !self.isFocused(view: self.searchField) {
            self.view
                .window?
                .makeFirstResponder(self.searchField)
            if let searchEditor = self.searchField.currentEditor() {
                searchEditor.moveToEndOfLine(nil)
            }
        }

        return event
    }

    func isFocused(view: NSView) -> Bool {
        guard let focusedView = self.view
            .window?
            .firstResponder as? NSView else {
            return false
        }
        if focusedView == view {
            return true
        }

        return focusedView.isDescendant(of: view)
    }
}

// TODO: Show favicons
// TODO: Show decrypted metadata
// TODO: Log errors
// TODO: Prompt to load at startup
// TODO: Exit button
// TODO: Settings
// TODO: Make recent results appear on top of ls
// TODO: Make recent results appear on clearing search field
// TODO: Move searchField settings into code
// TODO: Actually override selected/emphasized row color rather then play focus games
// TODO: Fix laggyness

extension HUDViewController: NSSearchFieldDelegate {
    func controlTextDidChange(_ obj: Notification) {
        self.runPassCommand(arguments: [
            "find", self.searchField.stringValue.lowercased()
        ])
    }
}

extension HUDViewController: CommandOutputStreamerDelegate {
    func handleOutput(_ output: String, commandIndex: Int) {
        // This ensures we only display output for the most recently
        // run command. If we see a newer command then we know about
        // then clear the existing results.
        if commandIndex < self.lastPassCommandReceivedIndex {
            return
        } else if commandIndex > self.lastPassCommandReceivedIndex {
            self.lastPassCommandReceivedIndex = commandIndex
            self.searchResults = []
        }

        self.searchResults = self.searchResults + output
            .split(separator: "\n")
            .filter({ $0.hasPrefix("|-- ") || $0.hasPrefix("`-- ") })
            .map({ String($0.dropFirst(4)) })
            .map({ $0.replacingOccurrences(of: "\\ ", with: " ") })

        self.searchResultsTableView.reloadData()

        if !self.isFocused(view: self.searchResultsTableView) {
            self.view
                .window?
                .makeFirstResponder(self.searchResultsTableView)
        }
    }

    func runPassCommand(arguments: [String]) {
        // TODO: This method needs an atomic compare and swap
        CommandOutputStreamer(
            launchPath: "/usr/bin/env",
            arguments: ["pass"] + arguments,
            caller: self,
            index: self.lastPassCommandSentIndex
        ).launch()
        self.lastPassCommandSentIndex = self.lastPassCommandSentIndex + 1
    }
}

extension HUDViewController: NSTableViewDelegate, NSTableViewDataSource {
    func numberOfRows(in tableView: NSTableView) -> Int {
        return self.searchResults.count
    }

    func tableView(
        _ tableView: NSTableView,
        objectValueFor tableColumn: NSTableColumn?,
        row: Int
    ) -> Any? {
        return (self.searchResults[row])
    }

    func selectedPassword() -> String? {
        var selectedRow = self.searchResultsTableView.selectedRow
        if selectedRow < 0 {
            selectedRow = 0
        }

        return self.searchResults[selectedRow]
    }

    func searchResultsViewClick() {
        guard let selectedPassword = self.selectedPassword() else {
            print("Failed to find selected password in search results")
            return
        }

        let task = Process()
        task.launchPath = "/usr/bin/env"
        task.arguments = ["pass", "show", "--clip", selectedPassword]
        var environment = ProcessInfo.processInfo.environment
        environment["PATH"] = "/usr/local/opt/gettext/bin:/sbin:/usr/sbin:/usr/local/bin:/usr/bin:/bin"
        task.environment = environment
        task.launch()
        task.waitUntilExit()
        // TODO: Check task.terminationStatus
        self.view.window?.orderOut(nil)
    }

    @objc func searchResultsViewClickHandler(_ sender: AnyObject) {
        self.searchResultsViewClick()
    }
}

extension HUDViewController {
    static func create() -> HUDViewController {
        let identifier = NSStoryboard.SceneIdentifier("HUDViewController")
        guard let viewController = NSStoryboard(
            name: NSStoryboard.Name("Main"),
            bundle: nil
        ).instantiateController(withIdentifier: identifier) as? HUDViewController else {
            fatalError("Failed to instantiate HUDViewController")
        }

        return viewController
    }
}
