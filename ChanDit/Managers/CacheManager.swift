//
//  CacheManager.swift
//  ChanDit
//
//  Created by Bemacash on 28/11/19.
//  Copyright © 2019 Vinicius Valvassori. All rights reserved.
//

import UIKit
import SDWebImage

class CacheManager: NSObject {
    static func clearWebmCache() {
        do {
            let url = try URLManager.getBaseDirectory(for: .cachesDirectory)
            try FileManager.default.removeItem(at: url)
        } catch {
            print("Failed to remove cache. Try again later.")
        }
    }

    static func clearImageDiskCache() {
        SDImageCache.shared.clearDisk()
    }

    static func clearImageMemoryCache() {
        SDImageCache.shared.clearMemory()
    }

}

class URLManager {
    static func getBaseDirectory(for path: FileManager.SearchPathDirectory) throws -> URL {
        let fileManager = FileManager.default
        let url = try fileManager.url(for: path, in: .userDomainMask,
                                      appropriateFor: nil, create: false)
        if path == .documentDirectory {
            return url.appendingPathComponent("webm", isDirectory: true)
        }
        let bundle: String = Bundle.main.bundleIdentifier ?? ""
        return url.appendingPathComponent(bundle, isDirectory: true).appendingPathComponent("webm", isDirectory: true)
    }
}
