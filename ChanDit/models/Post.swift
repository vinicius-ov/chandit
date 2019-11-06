//
//  Post.swift
//  ChanDit
//
//  Created by Vinicius Valvassori on 02/08/19.
//  Copyright © 2019 Vinicius Valvassori. All rights reserved.
//

import UIKit

struct Post: Decodable {
    var number: Int?
    var now: String?
    var name: String?
    var com: String?
    var sub: String?
    var filename: String?
    var ext: String?
    var md5: String?
    var imageWidth: Int? 
    var imageHeight: Int?
    var thumbWidth: Int?
    var thumbHeight: Int?
    var tim: Int? //??
    var time: Int?
    var fsize: Int?
    var resto: Int?
    var bumplimit: Int?
    var imagelimit: Int?
    var semanticUrl: String? //semantic_url
    var customSpoiler: Int? //custom_spoiler
    var replies: Int?
    var images: Int?
    var omittedPosts: Int? //ommited_posts
    var omittedImages: Int? //ommited_images
    var tailSize: Int? //tail_size
    var tripCode: String?
    var spoiler: Int?
    var sticky: Int?
    var closed: Int?
    var fileDeleted: Int?
    var archived: Int?
    var archivedOn: String?
    
    enum CodingKeys: String, CodingKey {
        case number = "no"
        case now
        case name
        case com
        case sub
        case filename
        case ext
        case md5
        case imageWidth = "w"
        case imageHeight = "h"
        case thumbWidth = "tn_w"
        case thumbHeight = "tn_h"
        case tim
        case time
        case fsize
        case resto
        case bumplimit
        case imagelimit
        case semanticUrl = "semantic_url"
        case customSpoiler = "custom_spoiler"
        case replies
        case images
        case omittedPosts = "omitted_posts"
        case omittedImages = "omitted_images"
        case tailSize = "tail_size"
        case tripCode = "trip"
        case spoiler
        case sticky
        case closed
        case fileDeleted = "filedeleted"
        case archived
        case archivedOn = "archive_on"
    }
}

struct Thread: Decodable, Comparable {
    static func < (lhs: Thread, rhs: Thread) -> Bool {
        guard let postLhs = lhs.posts.first, let numberLhs = postLhs.number,
        let postRhs = rhs.posts.first, let numberRhs = postRhs.number
            else { return false }
        return numberLhs < numberRhs
    }
    
    static func == (lhs: Thread, rhs: Thread) -> Bool {
        return lhs.posts.first!.number == rhs.posts.first!.number
    }

}
struct Thread: Decodable {
    let posts: [Post]
}
    
struct Page: Decodable {
    let threads: [Thread]
}
