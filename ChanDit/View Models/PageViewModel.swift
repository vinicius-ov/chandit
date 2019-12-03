//
//  PageViewModel.swift
//  ChanDit
//
//  Created by Bemacash on 22/11/19.
//  Copyright © 2019 Vinicius Valvassori. All rights reserved.
//

import UIKit

struct PageViewModel {
    var threads: [ThreadViewModel]

    func threadViewModel(at index: Int) -> ThreadViewModel? {
        return self.threads[index]
    }

    func canAppend(thread: ThreadViewModel) -> Bool {
        var retorno = true

        if threads.isEmpty {
            return retorno
        }

        threads.forEach {
            if $0.opNumber == thread.opNumber {
                retorno = false
                return
            }
        }

        return retorno
    }

}
