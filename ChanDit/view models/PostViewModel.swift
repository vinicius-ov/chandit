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
    
    func setNavigation(forThreadInSection section:Int, forPostInIndex index:Int) {
        
    }
}

struct ThreadViewModel {
    var posts = [PostViewModel]()
    var threadNumberToNavigate: Int!
    var postNumberToNavigate: Int?
    var boardIdToNavigate: String!
    
    init(thread: Thread) {
        //self.posts = [PostViewModel]()
        self.posts = thread.posts.map(PostViewModel.init)
    }
    
    func findPostIndexByNumber(_ number: Int?) -> Int? {
        let index = posts.firstIndex(where: { (post) -> Bool in
            post.number == number
        })
        return index
    }
    
    init(threadNumberToNavigate: Int, postNumberToNavigate: Int?, originBoard: String?){
        self.threadNumberToNavigate = threadNumberToNavigate
        self.postNumberToNavigate = postNumberToNavigate
        self.boardIdToNavigate = originBoard
    }
    
//    init() {
//        posts = [PostViewModel]()
//    }
    
    func postViewModel(at index: Int) -> PostViewModel {
        return self.posts[index]
    }
    
    var threadTitle:String {
        let op = posts.first!
        return op.title ?? op.subject ?? ""
    }
}

struct PostViewModel {
    var post: Post
}

extension PostViewModel {
    
    var comment: String? {
        let formatString = post.com?.replacingOccurrences(of: "#p", with: "http://a.z/")
        return formatString
    }
    
    var title: String? {
        return post.sub
    }
    
    var isSpoiler: Bool {
        return post.spoiler == 1
    }
    
    var resto: Int? {
        return post.resto
    }
    
    var number: Int? {
        return post.no
    }

    func thumbnailUrl(boardId: String) -> URL? {
        guard let tim = post.tim else {
            return URL(string: "")
        }
        return URL(string: "https://i.4cdn.org/\(boardId)/\(tim)s.jpg")
    }
    
    var thumbWidth: CGFloat? {
        return CGFloat.init(exactly: NSNumber(value: post.tn_w ?? 0))
    }
    
    var thumbHeight: CGFloat? {
        return CGFloat.init(exactly: NSNumber(value: post.tn_h ?? 0))
    }

    func imageUrl(boardId: String) -> URL? {
        guard let tim = post.tim, let ext = post.ext else {
            return URL(string: "")
        }
        return URL(string: "https://i.4cdn.org/\(boardId)/\(tim)\(ext)")
    }
    
    var timeFromPost: String? {
        let diff = getTimeAgo()
        let date = Date(timeIntervalSince1970: diff)
        let formatter = DateFormatter()
        formatter.timeZone = TimeZone(abbreviation: "GMT")
        formatter.locale = Locale(identifier: "pt_BR")
        formatter.dateFormat = "H"
        let hours = formatter.string(from: date)
        formatter.dateFormat = "mm"
        let minutes = formatter.string(from: date)
        return "\(hours)h\(minutes)m ago"
    }
    
    var postAuthorName: String? {
        return post.name ?? post.tripCode
    }
    
    var fileSize: String? {
        guard let filesize = post.fsize else { return "" }
        var fsize = Double(filesize)/1024.0
        var unit = "KiB"
        if fsize > 1024 {
            fsize = fsize / 1024
            unit = "MiB"
        }
        return String(format: "%.2f %@",fsize,unit)
    }
    
    var mediaFullName: String? {
        return "\(post.filename ?? "")\(post.ext ?? "")"
    }
    
    fileprivate func getTimeAgo() -> TimeInterval{
        let time = post.time
        
        let now = NSDate().timeIntervalSince1970
        
        let diff = now - Double(time ?? 0)
        return diff
    }
    
    var subject: String? {
        return post.sub
    }
    
    var imageWidth: CGFloat? {
        return CGFloat.init(exactly: NSNumber(value: post.w ?? 0))
    }
    
    var imageHeight: CGFloat? {
        return CGFloat.init(exactly: NSNumber(value: post.h ?? 0))
    }
}
