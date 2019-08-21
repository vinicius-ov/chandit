//
//  PostViewModel.swift
//  ChanDit
//
//  Created by Vinicius Valvassori on 09/08/19.
//  Copyright © 2019 Vinicius Valvassori. All rights reserved.
//

import UIKit

struct PageViewModel {
    var threads: [ThreadViewModel]
    
    init() {
        self.threads = [ThreadViewModel]()
    }
    
    func threadViewModel(at index: Int) -> ThreadViewModel {
        return self.threads[index]
    }
}

struct ThreadViewModel {
    var posts: [PostViewModel]
    
    init(thread: Thread) {
        self.posts = [PostViewModel]()
        self.posts = thread.posts.map(PostViewModel.init)
    }
    
    func postViewModel(at index: Int) -> PostViewModel {
        return self.posts[index]
    }
}

struct PostViewModel {
    var post: Post
}

extension PostViewModel {
    
    var comment: String? {
        return post.com
    }
    var thumbnailUrl: URL? {
        guard let tim = post.tim else {
            return URL(string: "")
        }
        return URL(string: "https://i.4cdn.org/v/\(tim)s.jpg")
    }
    var timeFromPost: String? {
        let diff = getTimeAgo()
        let date = Date(timeIntervalSince1970: diff)
        let formatter = DateFormatter()
        formatter.timeZone = TimeZone(abbreviation: "GMT")
        formatter.locale = Locale(identifier: "pt_BR")
        formatter.dateFormat = "HH"
        let hours = formatter.string(from: date)
        formatter.dateFormat = "mm"
        let minutes = formatter.string(from: date)
        return "\(hours) hours \(minutes) minutes ago"
    }
    
    var postAuthorName: String? {
        return post.name ?? post.tripCode
    }
    
    fileprivate func getTimeAgo() -> TimeInterval{
        let time = post.time
        
        let now = NSDate().timeIntervalSince1970
        
        let diff = now - Double(time ?? 0)
        return diff
    }
}
