//
//  HUDViewController.swift
//  PassHUD
//
//  Created by Nussbaum, Michael on 10/11/18.
//  Copyright © 2018 mnussbaum. All rights reserved.
//

import Cocoa

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
        self.searchResultsTableView.action = #selector(searchResultsViewClick(_:))
    }
}

// TODO: Make arrow keys useful for navigation
// TODO: Show favicons
// TODO: Show decrypted metadata
// TODO: Make dissappear when focus is lost
// TODO: Make dissappear when PW is copied
// TODO: Deal with space escaping in PW names
// TODO: Log errors
// TODO: Respond to enter key


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
    
    @objc func searchResultsViewClick(_ sender: AnyObject) {
        let selectedRow = self.searchResultsTableView.selectedRow
        if selectedRow < 0 {
            return
        }
        
        guard let selectedPassword = self.searchResults?[selectedRow] else {
            fatalError("Failed to find selected password in search results")
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
