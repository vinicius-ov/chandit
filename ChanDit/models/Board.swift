//
//  Board.swift
//  ChanDit
//
//  Created by Vinicius Valvassori on 02/09/19.
//  Copyright © 2019 Vinicius Valvassori. All rights reserved.
//

import UIKit

struct Board: Decodable, Comparable {
    static func < (lhs: Board, rhs: Board) -> Bool {
        return lhs.board < rhs.board
    }
    
    static func == (lhs: Board, rhs: Board) -> Bool {
        return lhs.board == rhs.board
    }
    
    var board: String
    var title: String
    var wsBoard: Int?
    var perPage: Int?
    var pages: Int?
    var maxFilesize: Int?
    var maxWebmFilesize: Int?
    var maxCommentChars: Int?
    var maxWebmDuration: Int?
    var bumpLimit: Int?
    var imageLimit: Int?
    var cooldowns: Cooldowns?
    var metaDescription: String?
    var customSpoilers: Int?
    var isArchived: Int?
    var is18Plus: Bool?
    
    enum CodingKeys: String, CodingKey {
        case board
        case title
        case wsBoard = "ws_board"
        case perPage = "per_page"
        case pages
        case maxFilesize = "max_filesize"
        case maxWebmFilesize = "max_webm_filesize"
        case maxCommentChars = "max_comment_chars"
        case maxWebmDuration = "max_webm_duration"
        case bumpLimit = "bump_limit"
        case imageLimit = "image_limit"
        case cooldowns
        case metaDescription = "meta_description"
        case isArchived = "is_archived"
        case customSpoilers = "custom_spoilers"
    }
}

struct Cooldowns: Decodable{
    var threads: Int?
    var replies: Int?
    var images: Int?
}

struct Boards: Decodable {
    let boards: [Board]?
    let trollFlags: [String:String]?
    
    enum CodingKeys: String, CodingKey {
        case boards
        case trollFlags = "troll_flags"
    }
}
