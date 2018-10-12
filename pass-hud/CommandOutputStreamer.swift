//
//  CommandOutputStreamer.swift
//  pass-hud
//
//  Created by Nussbaum, Michael on 10/11/18.
//  Copyright © 2018 mnussbaum. All rights reserved.
//

import Cocoa

protocol CommandOutputStreamerDelegate {
    func handleOutput(_ output: String)
}

class CommandOutputStreamer {
    var delegate: CommandOutputStreamerDelegate
    var task: Process
    
    init(
        launchPath: String,
        arguments: [String],
        caller: CommandOutputStreamerDelegate
    ) {
        delegate = caller
        task = Process()
        task.launchPath = launchPath
        task.arguments = arguments
        var environment = ProcessInfo.processInfo.environment
        // TODO: :(
        environment["PATH"] = "/usr/local/opt/gettext/bin:/sbin:/usr/sbin:/usr/local/bin:/usr/bin:/bin"
        task.environment = environment
        
        let pipe = Pipe()
        task.standardOutput = pipe
        
        let outputHandle = pipe.fileHandleForReading
        outputHandle.waitForDataInBackgroundAndNotify()
        
        // TODO: make queue non-nil so this runs in the background
        var dataAvailable : NSObjectProtocol!
        dataAvailable = NotificationCenter.default.addObserver(
            forName: NSNotification.Name.NSFileHandleDataAvailable,
            object: outputHandle, queue: nil
        ) {  notification -> Void in
            let data = pipe.fileHandleForReading.availableData
            if data.count <= 0 {
                NotificationCenter.default.removeObserver(dataAvailable)
                return
            }
            
            if let str = String(data: data, encoding: .utf8) {
                self.delegate.handleOutput(str)
            }
            
            outputHandle.waitForDataInBackgroundAndNotify()
        }
    }
    
    func launch() {
        return task.launch()
    }

}
