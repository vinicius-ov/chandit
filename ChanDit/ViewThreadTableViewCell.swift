//
//  ViewThreadTableViewCell.swift
//  ChanDit
//
//  Created by Vinicius Valvassori on 23/08/19.
//  Copyright © 2019 Vinicius Valvassori. All rights reserved.
//

import UIKit

class ViewThreadTableViewCell: UITableViewCell {

    var originalPostNumber: Int?
    @IBOutlet weak var viewThread: UIButton!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }
    
//    @IBAction func viewThread() {
//        print(originalPostNumber)
//    }

}
