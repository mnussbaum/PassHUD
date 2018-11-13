//
//  FaviconLoader.swift
//  PassHUD
//
//  Created by Nussbaum, Michael on 10/27/18.
//  Copyright © 2018 mnussbaum. All rights reserved.
//

import os

import FavIcon
import SPTPersistentCache

class FaviconLoader {
    var cache: SPTPersistentCache

    let systemCachePath = NSSearchPathForDirectoriesInDomains(
        .cachesDirectory,
        .userDomainMask,
        true
    ).first!
    let cacheIdentifier = "com.passhud.favicon.cache"
    var cachePath: String
    let cacheQueue = DispatchQueue(label: "com.passhud.favicon.cache")
    let cacheOptions = SPTPersistentCacheOptions()
    let thirtyDays = 60 * 60 * 24 * 30

    let domainPredicate = NSPredicate(
        format:"SELF MATCHES %@",
        argumentArray: [
            "^(www\\.)?([-a-z0-9]{1,63}\\.)*?[a-z0-9][-a-z0-9]{0,61}[a-z0-9]\\.[a-z]{2,6}(/[-\\w@\\+\\.~#\\?&/=%]*)?$"
        ]
    )

    init() {
        self.cachePath = self.systemCachePath.appending(
            self.cacheIdentifier
        )

        self.cacheOptions.cachePath = self.cachePath;
        self.cacheOptions.cacheIdentifier = self.cacheIdentifier
        self.cacheOptions.defaultExpirationPeriod = UInt(self.thirtyDays)
        self.cacheOptions.garbageCollectionInterval = UInt(60 * 60) * SPTPersistentCacheDefaultGCIntervalSec
        self.cacheOptions.sizeConstraintBytes = 1024 * 1024 * 200; // 200 MiB

        self.cache = SPTPersistentCache(options: self.cacheOptions)
        self.cache.scheduleGarbageCollector()
    }

    func isDomain(candidate: String) -> Bool {
        return self.domainPredicate.evaluate(with: candidate)
    }

    func load(
        _ domain: String?,
        callback: @escaping (NSImage?)  -> Void
    ) {
        guard let domain = domain else { return }
        if !isDomain(candidate: domain) { return }

        self.cache.loadData(
            forKey: domain,
            withCallback: { (cacheResponse) in
                if cacheResponse.result == .operationSucceeded{
                    callback(NSImage(data: cacheResponse.record.data))
                } else {
                    self.downloadFavicon(
                        domain,
                        attempt: 0,
                        callback: callback
                    )
                }
            },
            on: DispatchQueue.main
        )

        return
    }

    func downloadFavicon(
        _ domain: String,
        attempt: Int,
        callback: @escaping (NSImage?)  -> Void
    ) {
        var scheme = "https"
        if attempt == 1 {
            scheme = "http"
        } else if attempt > 1 {
            return
        }

        try! FavIcon.downloadPreferred(scheme + "://" + domain) { result in
            guard case let .success(image) = result else {
                self.downloadFavicon(
                    domain,
                    attempt: attempt + 1,
                    callback: callback
                )
                return
            }

            callback(image)

            if let tiffImage = image.tiffRepresentation {
                // Stagger cache expiration to avoid thundering hurds
                let ttl = self.cacheOptions.defaultExpirationPeriod + UInt(Int.random(in: 0 ..< self.thirtyDays))
                self.cache.store(
                    tiffImage,
                    forKey: domain,
                    ttl: ttl,
                    locked: false,
                    withCallback: { (cacheResponse) in
                        if cacheResponse.result != .operationSucceeded {
                            os_log(
                                "Failed to store favicon for %{public}@ to cache: %{public}@",
                                type: .error,
                                domain,
                                cacheResponse.error.localizedDescription
                            )
                        }
                    },
                    on: self.cacheQueue
                )
            }
        }
    }
}
