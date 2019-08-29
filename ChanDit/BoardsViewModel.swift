//
//  BoardsViewModel.swift
//  ChanDit
//
//  Created by Vinicius Valvassori on 29/08/19.
//  Copyright © 2019 Vinicius Valvassori. All rights reserved.
//

import UIKit

class BoardsViewModel: NSObject {
    let usIdentifier = "last_board_selected"
    
    let boards = [
        BoardData(name: "Anime & Manga", endpoint: "a"),
        BoardData(name: "Politically Correct", endpoint: "pol"),
        BoardData(name: "Video Games", endpoint: "v")
    ]
    
    struct BoardData: Encodable,Decodable {
        var name: String
        var endpoint: String
    }
    
    private var currentBoard: BoardData? {
        guard let selected = UserDefaults.standard.string(forKey: usIdentifier) else {
            return boards.first!
        }
        return getBoardByName(name: selected)
        
    }
    
    var selectedBoardName: String {
        guard let selected = currentBoard else {
            return boards.first!.name
        }
        return selected.name
    }

    var selectedBoardId: String {
        guard let selected = currentBoard else {
            return boards.first!.endpoint
        }
        return selected.endpoint
    }
    
    func setCurrentBoard(byBoardName name: String) {
        //let board = getBoardByName(name: name)
        //let encoded = NSKeyedArchiver.archivedData(withRootObject: board)
        UserDefaults.standard.set(name, forKey: usIdentifier)
    }
    
    func getBoardByName(name: String) -> BoardData{
        let filtered = boards.filter {
            $0.name == name
        }
        return filtered.first!
    }
}
