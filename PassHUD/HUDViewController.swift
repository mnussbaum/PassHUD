//
//  HUDViewController.swift
//  PassHUD
//
//  Created by Nussbaum, Michael on 10/11/18.
//  Copyright © 2018 mnussbaum. All rights reserved.
//

import Cocoa
import Carbon
import os

class HUDViewController: NSViewController  {
    @IBOutlet weak var searchField: NSTextField!
    @IBOutlet weak var searchResultsTableView: NSTableView!

    let visualEffect = NSVisualEffectView()

    var searchResults: [String] = []
    var recentlyUsed = LRUCache(capacity: 100)
    var recentlyUsedLock = NSLock()

    let faviconLoader = FaviconLoader()


    let lastPassCommandSentIndex = Atomic(value: 0)
    let lastPassCommandReceivedIndex = Atomic(value: 0)

    func activate() {
        self.view.window?.center()
        self.view.window?.makeKeyAndOrderFront(nil)
        self.searchField.stringValue = ""

        self.controlTextDidChange(Notification(name: Notification.Name(rawValue: "Activate")))
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        self.visualEffect.blendingMode = .behindWindow
        self.visualEffect.state = .followsWindowActiveState
        self.visualEffect.material = .ultraDark
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

        self.view
            .window?
            .makeFirstResponder(self.searchResultsTableView)
    }

    func keyDown(with event: NSEvent) -> NSEvent? {
        if Int(event.keyCode) == kVK_Return {
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

        return focusedView == view || focusedView.isDescendant(of: view)
    }
}

extension HUDViewController: NSTextFieldDelegate {
    func  controlTextDidChange(_ obj: Notification) {
        if self.searchField.stringValue == "" {
            self.runPassCommand(arguments: ["ls"])
        } else {
            self.runPassCommand(arguments: [
                "find", self.searchField.stringValue.lowercased()
            ])
        }
    }
}

extension HUDViewController: CommandOutputStreamerDelegate {
    func handleOutput(
        _ output: String,
        arguments: [String]?,
        commandIndex: Int
    ) {
        // This ensures we only display output for the most recently
        // run command. If we see a newer command then we know about
        // then clear the existing results.

        self.lastPassCommandReceivedIndex.set { [weak self] (current) -> (Int) in
            guard let strongSelf = self else { return current }

            if commandIndex < current {
                return current
            } else if let arguments = arguments, arguments.contains("ls"), commandIndex > current {
                // Populate recently used above the normal full list shown on empty search
                strongSelf.recentlyUsedLock.lock()
                strongSelf.searchResults = Array(strongSelf.recentlyUsed) as! [String]
                strongSelf.recentlyUsedLock.unlock()
            } else if commandIndex > current {
                strongSelf.searchResults = []
            }

            let searchResultSet = Set(strongSelf.searchResults)
            strongSelf.searchResults = strongSelf.searchResults + output
                .split(separator: "\n")
                .filter({
                    $0.hasPrefix("├── ") || $0.hasPrefix("└── ") ||
                    $0.hasPrefix("|-- ") || $0.hasPrefix("`-- ")
                })
                .map({ String($0.dropFirst(4)) })
                .map({ $0.replacingOccurrences(of: "\\ ", with: " ") })
                .filter({ !searchResultSet.contains($0) })

            strongSelf.searchResultsTableView.reloadData()
            return commandIndex
        }
    }

    func runPassCommand(arguments: [String]) {
        self.lastPassCommandSentIndex.set { [weak self] (current) -> (Int) in
            guard let strongSelf = self else { return current }

            CommandOutputStreamer(
                launchPath: "/usr/bin/env",
                arguments: ["pass"] + arguments,
                caller: strongSelf,
                index: current
            ).launch()

            return current + 1
        }
    }
}

extension HUDViewController: NSTableViewDelegate, NSTableViewDataSource {
    func numberOfRows(in tableView: NSTableView) -> Int {
        return self.searchResults.count
    }

    func tableView(
        _ tableView: NSTableView,
        viewFor tableColumn: NSTableColumn?,
        row: Int
    ) -> NSView? {
        guard let cellView = tableView.makeView(
            withIdentifier: NSUserInterfaceItemIdentifier(
                rawValue: "SearchResultCell"
            ),
            owner: nil
        ) as? HUDTableCellView else {
            return nil
        }

        let rowResult = self.searchResults[row]
        cellView.textField?.stringValue = rowResult
        cellView.imageView?.image = nil

        self.faviconLoader.load(
            self.searchResults[row],
            callback: { (maybeFavicon) in
                // This is still race-prone
                if let favicon = maybeFavicon, rowResult == cellView.textField?.stringValue {
                    cellView.imageView?.image = favicon
                }
            }
        )

        return cellView
    }

    func selectedSearchResult() -> String? {
        var selectedRow = self.searchResultsTableView.selectedRow
        if selectedRow < 0 {
            selectedRow = 0
        }

        if self.searchResults.count <= selectedRow {
            return nil
        }

        return self.searchResults[selectedRow]
    }

    func searchResultsViewClick() {
        guard let selectedSearchResult = self.selectedSearchResult() else {
            return
        }

        self.recentlyUsedLock.lock()
        self.recentlyUsed.addValue(selectedSearchResult)
        self.recentlyUsedLock.unlock()

        let task = Process()
        task.launchPath = "/usr/bin/env"
        task.arguments = ["pass", "show", "--clip", selectedSearchResult]
        var environment = ProcessInfo.processInfo.environment
        environment["PATH"] = "/usr/local/opt/gettext/bin:/sbin:/usr/sbin:/usr/local/bin:/usr/bin:/bin"
        task.environment = environment
        task.launch()
        DispatchQueue.main.async {
            task.waitUntilExit()
            if task.terminationStatus != 0 {
                os_log(
                    "Error, non-zero exit code running pass show on %{public}@",
                    type: .error,
                    selectedSearchResult
                )
            }
        }

        self.view.window?.orderOut(nil)
        NSApp.hide(nil)
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
