//
//  BoardsViewModel.swift
//  ChanDit
//
//  Created by Vinicius Valvassori on 29/08/19.
//  Copyright © 2019 Vinicius Valvassori. All rights reserved.
//

import UIKit

class BoardsViewModel {
    let usIdentifier = "last_board_selected"
    var page = 0
    
    var postNumberToNavigate:Int? = 0
    var threadToLaunch:Int? = 0
    
    var boards: [Board]
//        BoardData(name: "Anime & Manga", endpoint: "a"),
//        BoardData(name: "Anime/Cute", endpoint: "c"),
//        BoardData(name: "Anime/Wallpapers", endpoint: "w"),
//        BoardData(name: "Mecha", endpoint: "m"),
//        BoardData(name: "Cosplay & CGL", endpoint: "cgl"),
//        BoardData(name: "Cute/Male", endpoint: "m"),
//        BoardData(name: "Flash", endpoint: "f"),
//        BoardData(name: "Transportation", endpoint: "n"),
//        BoardData(name: "Otaku Culture", endpoint: "jp"),
//        BoardData(name: "Politically Correct", endpoint: "pol"),
//        BoardData(name: "Video Games", endpoint: "v"),
//        BoardData(name: "Video Game Generals", endpoint: "vg")
//    ]
    
//    struct BoardData: Encodable,Decodable {
//        var name: String
//        var endpoint: String
//    }
    
    init() {
        boards = [Board]()
    }
    
    private var currentBoard: Board? {
        guard let selected = UserDefaults.standard.string(forKey: usIdentifier) else {
            return boards.first
        }
        return getBoardByName(title: selected)
    }
    
    func nextPage() -> Int {
        page = page + 1
        return page
    }
    
    var selectedBoardName: String {
        guard let selected = currentBoard else {
            return boards.first!.title!
        }
        return selected.title!
    }

    var selectedBoardId: String? {
        guard let selected = currentBoard else {
            return boards.first?.board
        }
        return selected.board!
    }
    
    func setCurrentBoard(byBoardName name: String) {
        UserDefaults.standard.set(name, forKey: usIdentifier)
    }
    
    func getBoardByName(title: String) -> Board {
        let filtered = boards.filter {
            $0.title == title
        }
        return filtered.first!
    }
    
    func reset() {
        page = 0
        resetNavigation()
    }
    
    func resetNavigation() {
        postNumberToNavigate = nil
        threadToLaunch = nil
    }

}
