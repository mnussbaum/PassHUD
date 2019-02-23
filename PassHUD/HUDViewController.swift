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

    var passPath: String?
    var passEnvironment: Dictionary<String, String>?
    let faviconLoader = FaviconLoader()

    let lastPassCommandSentIndex = Atomic(value: 0)
    let lastPassCommandReceivedIndex = Atomic(value: 0)

    let padLockImage = NSImage(named:NSImage.Name("PadLockStatusBarButtonImage"))
    let rowViewIdentifier = NSUserInterfaceItemIdentifier(
        rawValue: "SearchResultRow"
    )
    let cellViewIdentifier = NSUserInterfaceItemIdentifier(
        rawValue: "SearchResultCell"
    )

    var passOutputLinePrefixRegex: NSRegularExpression?

    func windowIsVisible() -> Bool {
        if let window = self.view.window {
            return window.occlusionState.contains(.visible)
        }

        return false
    }

    func toggle(_ sender: Any?) {
        if self.windowIsVisible() {
            self.view.window?.orderOut(sender)
            NSApp.hide(sender)
            NSApp.deactivate()
            self.searchField.stringValue = ""
            self.controlTextDidChange(Notification(
                name: Notification.Name(rawValue: "Toggle")
            ))
            return
        }

        NSApp.activate(ignoringOtherApps: true)
        self.view.window?.center()
        self.view.window?.makeKeyAndOrderFront(nil)
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

        self.searchField.stringValue = ""
        self.controlTextDidChange(Notification(
            name: Notification.Name(rawValue: "Activate")
        ))

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
        } else if Int(event.keyCode) == kVK_Escape {
            self.toggle(nil)
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
    func controlTextDidChange(_ obj: Notification) {
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
    func handleOutput(_ output: String, arguments: [String]?, commandIndex: Int) {
        self.lastPassCommandReceivedIndex.set { [weak self] (current) -> (Int) in
            guard let strongSelf = self else { return current }

            // This ensures we only display output for the most recently
            // run command. If we see a newer command then we know about
            // then clear the existing results.
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

            let outputLines = output
                .split(separator: "\n")
                .map({ $0.replacingOccurrences(of: "\\ ", with: " ") })

            // Each outputLine could either contain a directory or an actual
            // search result. Actual search results should be shown with their
            // directory path prefixed in front of them aka
            // ADirectory/AnotherDirectory/ASearchResult. Directories shouldn't
            // be shown as individual search results.
            //
            // We can only determine if an entry is a directory or a search
            // result by looking at the following entry. If an entry is indented
            // more than its preceeding entry then the preceeding entry is a
            // directory, otherwise the preceeding entry is a terminal entry.
            //
            // For each entry we add it to an accumulator of nested results.
            // When we discover a terminal entry we join together the full
            // nested result path for it and add it to the search results. We
            // then truncate the accumulating directory results up to the depth
            // of the current entry, since we've confirmed we're done with that
            // deep directory path.
            var foundResults: [String] = []
            var nestingResults: [String] = []
            var lastEntry: (contents: String, depth: Int)? = nil

            guard let passOutputLinePrefixRegex = self?.passOutputLinePrefixRegex else {
                os_log(
                    "Error, unable to instantiate static NSRegularExpression",
                    log: logger,
                    type: .error
                )
                return 0
            }

            for outputLine in outputLines {
                guard let passOutputLinePrefix = passOutputLinePrefixRegex.firstMatch(
                    in: outputLine,
                    options: [],
                    range: NSRange(location: 0, length: outputLine.count)
                ) else {
                    continue
                }

                let passOutputLinePrefixStart = outputLine.index(
                    outputLine.startIndex,
                    offsetBy: passOutputLinePrefix.range.location + passOutputLinePrefix.range.length
                )
                let passOutputLinePrefixRange = passOutputLinePrefixStart..<outputLine.endIndex
                let currentEntry = (
                    contents: String(outputLine[passOutputLinePrefixRange]),
                    depth: passOutputLinePrefix.range.location / 4
                )

                // This means the lastEntry is a terminal entry
                if let foundLastEntry = lastEntry, currentEntry.depth <= foundLastEntry.depth {
                    let lastSearchResult = nestingResults.joined(separator: "/")
                    if !searchResultSet.contains(lastSearchResult) {
                        foundResults.append(lastSearchResult)
                    }
                    // Remove directories with indent >= current element's indent
                    nestingResults.removeSubrange(currentEntry.depth...)
                }
                nestingResults.append(currentEntry.contents)
                lastEntry = currentEntry
            }

            // The loop above only adds terminal entries (aka not directories)
            // to the foundResults. Unfortunately the final output line could
            // either be a directory or a terminal entry. We always add a final
            // entry to the search results since it's likely a terminal entry,
            // if it is a directory that will show though, and that's a bug.
            if lastEntry != nil && nestingResults.count > 0 {
                foundResults.append(nestingResults.joined(separator: "/"))
            }

            strongSelf.searchResults = strongSelf.searchResults + foundResults
            strongSelf.searchResultsTableView.reloadData()

            return commandIndex
        }
    }

    func runPassCommand(arguments: [String]) {
        self.lastPassCommandSentIndex.set { [weak self] (current) -> (Int) in
            guard let strongSelf = self else { return current }

            let task = strongSelf.buildPassProcess()
            task.arguments?.append(contentsOf: arguments)

            CommandOutputStreamer(
                task: task,
                arguments: arguments,
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
        rowViewForRow row: Int
    ) -> NSTableRowView? {
        if let rowView = tableView.makeView(
            withIdentifier: NSUserInterfaceItemIdentifier(
                rawValue: "SearchResultRow"
            ),
            owner: self
        ) as? HUDTableRowView {
            rowView.index = row
            return rowView
        } else {
            let rowView = HUDTableRowView()
            rowView.identifier = self.rowViewIdentifier
            rowView.parentTableView = tableView
            rowView.index = row
            return rowView
        }
    }

    func tableView(
        _ tableView: NSTableView,
        viewFor tableColumn: NSTableColumn?,
        row: Int
    ) -> NSView? {
        guard let cellView = tableView.makeView(
            withIdentifier: self.cellViewIdentifier,
            owner: self
        ) as? HUDTableCellView else {
            os_log(
                "Error, unable to make new cell view",
                log: logger,
                type: .error
            )
            return nil
        }

        let rowResult = self.searchResults[row]
        cellView.textField?.stringValue = rowResult
        cellView.imageView?.image = padLockImage?.copyWithTint(color: rowResult.toRGB())

        cellView.imageView?.wantsLayer = true

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

        let task = self.buildPassProcess()
        task.arguments?.append(
            contentsOf: ["show", "--clip", selectedSearchResult]
        )
        task.launch()

        DispatchQueue.main.async {
            task.waitUntilExit()
            if task.terminationStatus != 0 {
                os_log(
                    "Error, non-zero exit code running pass show on %{public}@",
                    log: logger,
                    type: .error,
                    selectedSearchResult
                )
            }
        }

        self.toggle(nil)
    }

    @objc func searchResultsViewClickHandler(_ sender: AnyObject) {
        self.searchResultsViewClick()
    }

    func buildPassProcess() -> Process {
        let task = Process()
        task.launchPath = "/usr/bin/env"

        var passPath = "pass"
        if let overridePassPath = self.passPath {
            passPath = overridePassPath
        }
        task.arguments = [passPath]

        if let environment = self.passEnvironment {
            task.environment = environment
        }

        return task
    }
}

extension HUDViewController {
    static func create(config: Optional<Config>) -> HUDViewController {
        let identifier = NSStoryboard.SceneIdentifier("HUDViewController")
        guard let viewController = NSStoryboard(
            name: NSStoryboard.Name("Main"),
            bundle: nil
        ).instantiateController(withIdentifier: identifier) as? HUDViewController else {
            fatalError("Failed to instantiate HUDViewController")
        }
        guard let pathHelperPath = getPathHelperPath() else {
            return viewController
        }

        if let passPath = config?.pass?.commandPath {
            viewController.passPath = passPath
        }

        viewController.passEnvironment = ProcessInfo
            .processInfo
            .environment

        var configSetPathEnvVar = false
        for envVarPair in config?.pass?.env ?? [] {
            viewController.passEnvironment?[envVarPair.name] = envVarPair.value
            if envVarPair.name == "PATH" {
                configSetPathEnvVar = true
            }
        }
        if !configSetPathEnvVar {
            viewController.passEnvironment?["PATH"] = pathHelperPath
        }

        viewController.passOutputLinePrefixRegex = try! NSRegularExpression(pattern: "(├── |└── |\\|-- |`-- )")

        return viewController
    }
}

func getPathHelperPath() -> String? {
    let pathHelperTask = Process()
    pathHelperTask.launchPath = "/usr/libexec/path_helper"
    pathHelperTask.arguments = ["-s"]
    let pathHelperPipe = Pipe()
    pathHelperTask.standardOutput = pathHelperPipe
    pathHelperTask.launch()
    guard let pathHelperOutput = NSString(
        data: pathHelperPipe.fileHandleForReading.readDataToEndOfFile(),
        encoding: String.Encoding.utf8.rawValue
    ) else {
        return nil
    }

    let strippedPathHelperOutput = pathHelperOutput.trimmingCharacters(in: .whitespacesAndNewlines)
    guard let pathRegex = try? NSRegularExpression(pattern: "^PATH=\"(.+)\"; export PATH;$") else {
        return nil
    }

    guard let pathMatch = pathRegex.firstMatch(
        in: strippedPathHelperOutput,
        options: [],
        range: NSRange(location: 0, length: strippedPathHelperOutput.utf16.count)
    ) else {
        return nil
    }

    guard let pathRange = Range(pathMatch.range(at: 1), in: strippedPathHelperOutput) else {
        return nil
    }

    return String(strippedPathHelperOutput[pathRange])
}
