//
//  Post.swift
//  ChanDit
//
//  Created by Vinicius Valvassori on 02/08/19.
//  Copyright © 2019 Vinicius Valvassori. All rights reserved.
//

import UIKit

struct Post: Decodable {
    var no: Int?
    var now: String?
    var name: String?
    var com: String?
    var sub: String?
    var filename: String?
    var ext: String?
    var md5: String?
    var w: Int?
    var h: Int?
    var tn_w: Int?
    var tn_h: Int?
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
    
    enum CodingKeys: String, CodingKey {
        case no
        case now
        case name
        case com
        case sub
        case filename
        case ext
        case md5
        case w
        case h
        case tn_w
        case tn_h
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
    }

}
struct Thread: Decodable {
    let posts: [Post]
}
struct Page: Decodable {
    let threads: [Thread]
}


