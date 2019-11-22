//
//  PageViewModel.swift
//  ChanDit
//
//  Created by Bemacash on 22/11/19.
//  Copyright © 2019 Vinicius Valvassori. All rights reserved.
//

import UIKit

struct PageViewModel {
    var threads: NSMutableOrderedSet!

    init() {
        self.threads = NSMutableOrderedSet()
    }

    func threadViewModel(at index: Int) -> ThreadViewModel? {
        return self.threads![index] as? ThreadViewModel
    }

}
