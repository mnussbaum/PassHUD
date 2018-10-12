//
//  HUDViewController.swift
//  pass-hud
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
        
        self.searchResultsTableView.delegate = self
        self.searchResultsTableView.dataSource = self
        self.searchResultsTableView.target = self
        self.searchResultsTableView.action = #selector(searchResultsViewClick(_:))
    }
}

extension HUDViewController: NSSearchFieldDelegate {
    func controlTextDidChange(_ obj: Notification) {
        guard let textField = obj.object as? NSTextField else { return }
        CommandOutputStreamer(
            launchPath: "/usr/bin/env",
            arguments: ["pass", "find", textField.stringValue.lowercased()],
            caller: self
            ).launch()
    }
    
    
    @objc func searchResultsViewClick(_ sender:AnyObject) {
        let selectedRow = self.searchResultsTableView.selectedRow
        if selectedRow < 0 {
            return
        }
        
        let item = self.searchResults?[selectedRow]
    }
}

extension HUDViewController: CommandOutputStreamerDelegate {
    func handleOutput(_ output: String) {
        self.searchResults = output
            .split(separator: "\n")
            .filter({ !$0.hasPrefix("Search Terms: ") })
            .map({ String($0.dropFirst(4)) })

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
