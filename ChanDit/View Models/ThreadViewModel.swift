//
//  ThreadViewModel.swift
//  ChanDit
//
//  Created by Bemacash on 22/11/19.
//  Copyright © 2019 Vinicius Valvassori. All rights reserved.
//

import UIKit

class ThreadViewModel: NSObject {
    var posts = [PostViewModel]()
    var threadNumberToNavigate: Int!
    var postNumberToNavigate: Int?
    var boardIdToNavigate: String!
    var completeBoardName: String?
    var isHidden: Bool = false

    init(thread: Thread) {
        self.posts = thread.posts.map(PostViewModel.init)
    }

    func findPostIndexByNumber(_ number: Int?) -> Int? {
        let index = posts.firstIndex(where: { (post) -> Bool in
            post.number == number
        })
        return index
    }

    init(threadNumberToNavigate: Int, postNumberToNavigate: Int?, originBoard: String?, completeBoardName: String?) {
        self.threadNumberToNavigate = threadNumberToNavigate
        self.postNumberToNavigate = postNumberToNavigate
        self.boardIdToNavigate = originBoard
        self.completeBoardName = completeBoardName
    }

    func reset() {
        postNumberToNavigate = nil
    }

    func postViewModel(at index: Int) -> PostViewModel? {
        if self.posts.isEmpty {
            return nil
        }
        return self.posts[index]
    }

    var threadTitle: String {
        let opThread = posts.first!
        return opThread.title ?? opThread.subject ?? ""
    }

    var opNumber: Int? {
        return postViewModel(at: 0)?.number
    }

}
