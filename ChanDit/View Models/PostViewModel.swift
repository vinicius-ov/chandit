//
//  PostViewModel.swift
//  ChanDit
//
//  Created by Vinicius Valvassori on 09/08/19.
//  Copyright © 2019 Vinicius Valvassori. All rights reserved.
//  swiftlint:disable trailing_whitespace

import UIKit
import Foundation

class PostViewModel {
    var post: Post
    var hidden: Bool = false
    var quoted: [Int] = []
    
    init(post: Post) {
        self.post = post
    }
}

extension PostViewModel {

    var spoilerUrl: URL? {
        return URL(string: "https://s.4cdn.org/image/spoiler.png")
    }
    
    var comment: String? {
        let formatString: String? = post.com?.replacingOccurrences(of: "#p",
                                                                   with: "chandit://")
        return formatString
    }

    var quotes: [Int] {
        var afterquotes = [Int]()
        if let comm = post.com {
            let quotes = comm.components(separatedBy: "&gt;&gt;")
            for quote in quotes {
                let mid = quote.components(separatedBy: "</a>")
                if let quote = Int(mid.first ?? "") {
                    afterquotes.append(quote)
                }
            }
        }
        return afterquotes
    }

    var lowerRangeGreenText: [Int] {
        return (comment ?? "").indicesOf(string: "<span class=\"quote\">")
    }

    var upperRangeGreenText: [Int] {
        return (comment ?? "").indicesOf(string: "</span>")
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
        return post.number
    }

    func thumbnailUrl(boardId: String) -> URL? {
        guard let tim = post.tim else {
            return URL(string: "")
        }
        return URL(string: "https://i.4cdn.org/\(boardId)/\(tim)s.jpg")
    }
    
    var thumbWidth: CGFloat? {
        return CGFloat.init(exactly: NSNumber(value: post.thumbWidth ?? 0))
    }
    
    var thumbHeight: CGFloat? {
        return CGFloat.init(exactly: NSNumber(value: post.thumbHeight ?? 0))
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
        formatter.dateFormat = "m"
        let minutes = formatter.string(from: date)
        if hours == "0" {
            return "\(minutes)m ago"
        } else {
            return "\(hours)h\(minutes)m ago"
        }
    }
    
    var postAuthorName: String? {
        return post.name ?? post.tripCode
    }
    
    var fileSize: String? {
        guard let filesize: Int = post.fsize, filesize > 0 else { return "" }
        var fsize = Double(filesize)/1024.0
        var unit = "KiB"
        if fsize > 1024 {
            fsize /= 1024
            unit = "MiB"
        }
        return String(format: "%.2f %@", fsize, unit)
    }
    
    var mediaFullName: String? {
        guard let filename: String = post.filename,
              let extens: String = post.ext else { return ""}
        return "\(filename)\(extens)"
    }
    
    fileprivate func getTimeAgo() -> TimeInterval {
        let time = post.time
        
        let now = NSDate().timeIntervalSince1970
        
        let diff = now - Double(time ?? 0)
        return diff
    }

    var hasImage: Bool {
        return post.filename != nil
    }

    var subject: String? {
        return post.sub
    }
    
    var imageWidth: CGFloat? {
        return CGFloat.init(exactly: NSNumber(value: post.imageWidth ?? 0))
    }
    
    var imageHeight: CGFloat? {
        return CGFloat.init(exactly: NSNumber(value: post.imageHeight ?? 0))
    }
    
    var replies: Int? {
            return post.replies
        }
    
    var images: Int? {
        return post.images

    }
    var omittedPosts: Int? {
        return post.omittedPosts
    }

    var omittedImages: Int? {
        return post.omittedImages
    }
    
    var isPinned: Bool {
        return post.sticky == 1
    }
    
    var isClosed: Bool {
        return post.closed == 1
    }
    
    var flagCountryCode: String {
        if let countryCode = post.countryCode {
            return countryCode.lowercased()
        } else if let trollCountry = post.trollCountry {
            return "troll/\(trollCountry.lowercased())"
        } else {
            return ""
        }
    }
    
    var countryName: String {
        return post.countryName ?? ""
    }

    var isOp: Bool {
        return post.resto == 0
    }

    func toggleHidden() {
        self.hidden = !self.hidden
    }

    var isHidden: Bool {
        return hidden
    }

    var quotedAsHtml: String {
        var html = ""
        for quote in quoted {
            html += "<a href=\"chandit://\(quote)\" class=\"quotelink\">&gt;&gt;\(quote)</a>&#32;"
        }
        return html
    }
}
