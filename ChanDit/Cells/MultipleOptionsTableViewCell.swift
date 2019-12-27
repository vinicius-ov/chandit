//
//  MultipleOptionsTableViewCell.swift
//  ChanDit
//
//  Created by Bemacash on 19/11/19.
//  Copyright © 2019 Vinicius Valvassori. All rights reserved.
//

import UIKit

class MultipleOptionsTableViewCell: UITableViewCell {
    
    @IBOutlet weak var titleLabel: UILabel!

    @IBAction func valueChanged(_ sender: UISegmentedControl) {
        UserDefaults.standard.set(sender.selectedSegmentIndex, forKey: "webm_volume")
    }
}
