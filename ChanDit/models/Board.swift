//
//  Board.swift
//  ChanDit
//
//  Created by Vinicius Valvassori on 02/09/19.
//  Copyright © 2019 Vinicius Valvassori. All rights reserved.
//

import UIKit

struct Board: Decodable {
    var board: String?
    var title: String?
    var wsBoard: Int?
    var per_page: Int?
    var pages: Int?
    var maxFilesize: Int?
    var maxWebmFilesize: Int?
    var maxCommentChars: Int?
    var maxWebmDuration: Int?
    var bumpLimit: Int?
    var imageLimit: Int?
//    var cooldowns: {
//        varthreads: 600,
//        varreplies: 60,
//        varimages: 60
//    }
    var metaDescription: String?
    var isArchived: Int?
    
    enum CodingKeys: String, CodingKey {
        case board
        case title
        case wsBoard = "ws_board"
        case per_page
        case pages
        case maxFilesize = "max_filesize"
        case maxWebmFilesize = "max_webm_filesize"
        case maxCommentChars = "max_comment_chars"
        case maxWebmDuration = "max_webm_duration"
        case bumpLimit = "bump_limit"
        case imageLimit = "image_limit"
        case metaDescription = "meta_description"
        case isArchived = "is_archived"
    }
}
struct Boards: Decodable {
    let boards: [Board]
}
