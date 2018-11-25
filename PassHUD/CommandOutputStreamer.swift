//
//  CommandOutputStreamer.swift
//  PassHUD
//
//  Created by Nussbaum, Michael on 10/11/18.
//  Copyright © 2018 mnussbaum. All rights reserved.
//

import Cocoa

protocol CommandOutputStreamerDelegate {
    func handleOutput(_ output: String, arguments: [String]?, commandIndex: Int)
}

class CommandOutputStreamer {
    var task: Process

    init(
        launchPath: String,
        arguments: [String],
        caller: CommandOutputStreamerDelegate,
        index: Int
    ) {
        self.task = Process()
        self.task.launchPath = launchPath
        self.task.arguments = arguments
        var environment = ProcessInfo.processInfo.environment
        // TODO: :(
        environment["PATH"] = "/usr/local/opt/gettext/bin:/sbin:/usr/sbin:/usr/local/bin:/usr/bin:/bin"
        self.task.environment = environment

        var pipe: Pipe? = Pipe()
        self.task.standardOutput = pipe

        let outputHandle = pipe?.fileHandleForReading
        outputHandle?.waitForDataInBackgroundAndNotify()

        // TODO: make queue non-nil so this runs in the background
        var dataAvailable : NSObjectProtocol!
        dataAvailable = NotificationCenter.default.addObserver(
            forName: NSNotification.Name.NSFileHandleDataAvailable,
            object: outputHandle, queue: nil
        ) { notification -> Void in
            guard let strongPipe = pipe else { return }

            let data = strongPipe.fileHandleForReading.availableData
            if data.count <= 0 {
                NotificationCenter.default.removeObserver(dataAvailable)
                pipe = nil
                return
            }

            if let str = String(data: data, encoding: .utf8) {
                caller.handleOutput(
                    str.substring(
                        to: str.index(str.endIndex, offsetBy: -1)
                    ),
                    arguments: arguments,
                    commandIndex: index
                )
            }

            outputHandle?.waitForDataInBackgroundAndNotify()
        }
    }

    func launch() {
        return self.task.launch()
    }

}
