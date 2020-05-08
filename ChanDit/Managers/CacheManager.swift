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

    }

    static func clearImageDiskCache() {
        SDImageCache.shared.clearDisk()
    }

    static func clearImageMemoryCache() {
        SDImageCache.shared.clearMemory()
    }

    static func numberOfItensInCache() -> Int {
        return UserDefaults.videoCache.dictionaryRepresentation().keys.count
    }

    static func removeWebmCache() {
        for key in UserDefaults.videoCache.dictionaryRepresentation().keys {
            UserDefaults.videoCache.removeObject(forKey: key)
        }
        UserDefaults.videoCache.synchronize()
    }

}
