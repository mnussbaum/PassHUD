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
    var searchResults: [String]?
    let visualEffect = NSVisualEffectView()

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
    }

    func keyDown(with event: NSEvent) -> NSEvent? {
        if Int(event.keyCode) == kVK_Return {
            self.searchResultsViewClick()
            
            return nil
        } else if Int(event.keyCode) == kVK_DownArrow && self.isFocused(view: self.searchField) {
            self.view.window?.makeFirstResponder(self.searchResultsTableView)
            self.searchResultsTableView.selectRowIndexes(
                IndexSet(integer: 0),
                byExtendingSelection: false
            )

            return nil
        } else if Int(event.keyCode) == kVK_UpArrow && self.isFocused(view: self.searchResultsTableView) && self.searchResultsTableView.selectedRow == 0 {
            
            self.view.window?.makeFirstResponder(self.searchField)
            self.searchField.currentEditor()?.moveToEndOfLine(nil)
            
            self.searchResultsTableView.deselectAll(nil)
            
            return nil
        } else {
            return event
        }
    }
    
    func isFocused(view: NSView) -> Bool {
        let focusedView = self.view.window?.firstResponder as! NSView
        if focusedView == view {
            return true
        }

        return focusedView.isDescendant(of: view)
    }
}

// TODO: Respond to enter key
// TODO: Make arrow keys useful for navigation
// TODO: Show favicons
// TODO: Show decrypted metadata
// TODO: Make dissappear when focus is lost
// TODO: Make dissappear when PW is copied
// TODO: Log errors
// TODO: Prompt to load at startup

extension HUDViewController: NSSearchFieldDelegate {
    func controlTextDidChange(_ obj: Notification) {
        guard let textField = obj.object as? NSTextField else { return }
        CommandOutputStreamer(
            launchPath: "/usr/bin/env",
            arguments: ["pass", "find", textField.stringValue.lowercased()],
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
    ) -> Any?{
        return (self.searchResults?[row])!
    }
    
    func searchResultsViewClick() {
        var selectedRow = self.searchResultsTableView.selectedRow
        if selectedRow < 0 {
            selectedRow = 0
        }
        
        guard let selectedPassword = self.searchResults?[selectedRow] else {
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
