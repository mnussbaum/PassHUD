//
//  Config.swift
//  PassHUD
//
//  Created by Nussbaum, Michael on 12/7/18.
//  Copyright © 2018 mnussbaum. All rights reserved.
//

import os
import Foundation

import Yams

struct EnvVarPair: Codable {
    var name: String
    var value: String
}

struct PassConfig: Codable {
    var commandPath: Optional<String>
    var env: Optional<Array<EnvVarPair>>
}

struct Config: Codable {
    var version: Optional<String>
    var pass: Optional<PassConfig>
}

let potentialConfigPaths = [
    FileManager
        .default
        .homeDirectoryForCurrentUser
        .appendingPathComponent(".PassHUD"),
    FileManager
        .default
        .homeDirectoryForCurrentUser
        .appendingPathComponent(".config", isDirectory: true)
        .appendingPathComponent("PassHUD", isDirectory: true)
        .appendingPathComponent("config")
]

class ConfigParser {
    class func ParseConfig() -> Optional<Config> {
        let (maybeConfigPath, maybeRawConfig) = rawConfig()

        guard let configPath = maybeConfigPath else {
            return nil
        }
        guard let rawConfig = maybeRawConfig else {
            return nil
        }

        do {
            return try YAMLDecoder().decode(
                Config.self,
                from: rawConfig
            )
        } catch {
            os_log(
                "Error parsing config at %{public}@: %{public}@.",
                log: logger,
                type: .error,
                configPath.description,
                "\(error)"
            )
        }

        return nil
    }

    class func rawConfig() -> (Optional<URL>, Optional<String>) {
        for configPath in potentialConfigPaths {
            do {
                return try (configPath, String(contentsOf: configPath))
            } catch {
                continue
            }
        }

        return (nil, nil)
    }
}
