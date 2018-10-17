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

    var searchResults: [String]?
    var recentSearches: Set<String> = []

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
        CommandOutputStreamer(
            launchPath: "/usr/bin/env",
            arguments: ["pass", "ls"],
            caller: self
        ).launch()
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
// TODO: Make dissappear when focus is lost
// TODO: Make dissappear when PW is copied
// TODO: Log errors
// TODO: Prompt to load at startup
// TODO: Exit button
// TODO: Settings
// TODO: Make recent results appear on top of ls
// TODO: Make recent results appear on clearing search field
// TODO: Move searchField settings into code
// TODO: Actually override selected/emphasized row color rather then play focus games

extension HUDViewController: NSSearchFieldDelegate {
    func controlTextDidChange(_ obj: Notification) {
        CommandOutputStreamer(
            launchPath: "/usr/bin/env",
            arguments: ["pass", "find", self.searchField.stringValue.lowercased()],
            caller: self
        ).launch()
    }
}

extension HUDViewController: CommandOutputStreamerDelegate {
    func handleOutput(_ output: String) {
        self.searchResults = output
            .split(separator: "\n")
            .filter({ !$0.hasPrefix("Search Terms: ") })
            .map({ String($0.dropFirst(4)) })
            .filter({ !$0.isEmpty })
            .map({ $0.replacingOccurrences(of: "\\ ", with: " ") })

        self.searchResultsTableView.reloadData()

        if !self.isFocused(view: self.searchResultsTableView) {
            self.view
                .window?
                .makeFirstResponder(self.searchResultsTableView)
        }
    }
}

extension HUDViewController: NSTableViewDelegate, NSTableViewDataSource {
    func numberOfRows(in tableView: NSTableView) -> Int {
        return self.searchResults?.count ?? 0
    }

    func tableView(
        _ tableView: NSTableView,
        objectValueFor tableColumn: NSTableColumn?,
        row: Int
    ) -> Any? {
        return (self.searchResults?[row])!
    }

    func selectedPassword() -> String? {
        var selectedRow = self.searchResultsTableView.selectedRow
        if selectedRow < 0 {
            selectedRow = 0
        }
        
        return self.searchResults?[selectedRow]
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
