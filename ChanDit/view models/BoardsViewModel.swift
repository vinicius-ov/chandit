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
    
    let adult  = [
        "Sexy Beautiful Women",
        "Hardcore",
        "Handsome Men",
        "Hentai",
        "Ecchi",
        "Yuri",
        "Hentai/Alternative",
        "Yaoi",
        "Torrents",
        "High Resolution",
        "Adult GIF",
        "Adult Cartoons",
        "Adult Requests",
        "Random",
        "ROBOT9001",
        "Politically Incorrect",
        "International/Random",
        "Cams & Meetups",
        "Shit 4chan Says"
    ]
    
    init() {
        boards = [Board]()
    }
    
    var currentBoard: Board? {
        guard let selected = UserDefaults.standard.string(forKey: usIdentifier) else {
            return boards.first
        }
        return getBoardByTitle(title: selected)
    }
    
    func nextPage() -> Int {
        page = page + 1
        return page
    }
    
    var selectedBoardName: String {
        guard let selected = currentBoard else {
            return boards.first!.title
        }
        return "/\(selected.board)/ - \(selected.title)"
    }
    
    func  isAdult(title: String) -> Bool? {
        let board = getBoardByTitle(title: title)
        return adult.contains(board.title)
        //return board.is18Plus
    }

    var selectedBoardId: String? {
        guard let selected = currentBoard else {
            return boards.first?.board
        }
        return selected.board
    }
    
//    func setCurrentBoard(byBoardName name: String) {
//        UserDefaults.standard.set(name, forKey: usIdentifier)
//    }
    
    func setCurrentBoard(byIndex index: Int) {
        let board = boards[index]
        UserDefaults.standard.set(board.title, forKey: usIdentifier)
    }
    
    func getBoardByTitle(title: String) -> Board {
        let filtered = boards.filter {
            $0.title == title
        }
        return filtered.first!
    }
    
    func getCurrentBoardIndex() -> Int?{
        let board = currentBoard
        return boards.firstIndex(of: board!)
    }
    
    func completeBoardName(atRow row: Int) -> String {
        return "/\(boards[row].board)/ - \(boards[row].title)"
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
