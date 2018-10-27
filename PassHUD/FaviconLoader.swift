//
//  FaviconLoader.swift
//  PassHUD
//
//  Created by Nussbaum, Michael on 10/27/18.
//  Copyright © 2018 mnussbaum. All rights reserved.
//

import FavIcon

class FaviconLoader {
    let fileManager = FileManager.default
    let systemCachePath = FileManager.default.urls(
        for: .cachesDirectory,
        in: .userDomainMask
    ).first!
    let cacheIdentifier = "com.passhud.favicon.cache"
    var cachePath: URL

    let domainPredicate = NSPredicate(
        format:"SELF MATCHES %@",
        argumentArray: [
            "^(www\\.)?([-a-z0-9]{1,63}\\.)*?[a-z0-9][-a-z0-9]{0,61}[a-z0-9]\\.[a-z]{2,6}(/[-\\w@\\+\\.~#\\?&/=%]*)?$"
        ]
    )

    init() {
        self.cachePath = self.systemCachePath.appendingPathComponent(
            self.cacheIdentifier,
            isDirectory: true
        )
    }

    func isDomain(candidate: String) -> Bool {
        return self.domainPredicate.evaluate(with: candidate)
    }

    func domainCachePath(_ domain: String) -> String {
        return self.cachePath
            .appendingPathComponent(domain)
            .absoluteString
    }

    func load(_ domain: String?) -> NSImage? {
        guard let domain = domain else { return nil }
        if !isDomain(candidate: domain) { return nil }

        guard let faviconCachePath = URL.init(
            string: self.domainCachePath(domain)
            ) else { return nil }

        do {
            let faviconData = try NSData(contentsOf: faviconCachePath, options: NSData.ReadingOptions())
            return NSImage(data: faviconData as Data)
        } catch {
            downloadFavicon(domain, attempt: 0)
            return nil
        }
    }

    func createCacheDirIfNecessary() {
        var isDirectory = ObjCBool(true)
        if self.fileManager.fileExists(
            atPath: self.cachePath.absoluteString,
            isDirectory: &isDirectory
        ) {
            return
        }

       try! self.fileManager.createDirectory(
            at: self.cachePath,
            withIntermediateDirectories: true
        )
    }

    func downloadFavicon(
        _ domain: String,
        attempt: Int
    ) {
        var scheme = "https"
        if attempt == 1 {
            scheme = "http"
        } else if attempt > 1 {
            return
        }

        self.createCacheDirIfNecessary()
        try! FavIcon.downloadPreferred(scheme + "://" + domain) { result in
            if case .failure = result {
                self.downloadFavicon(domain, attempt: attempt + 1)
            }

            guard let faviconCachePath = URL.init(
                string: self.domainCachePath(domain)
            ) else { return }

            if case let .success(image) = result {
                if let tiffImage = image.tiffRepresentation {
                    try! tiffImage.write(
                        to: faviconCachePath
                    )
                }
            }
        }
    }
}
