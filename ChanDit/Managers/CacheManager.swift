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
        UserDefaults.videoCache.removePersistentDomain(
            forName: "webm.chandit")
        UserDefaults.videoCache.synchronize()
    }

    static func clearImageDiskCache() {
        SDImageCache.shared.clearDisk()
    }

    static func clearImageMemoryCache() {
        SDImageCache.shared.clearMemory()
    }

}
