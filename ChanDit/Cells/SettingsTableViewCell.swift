//
//  SettingsTableViewCell.swift
//  ChanDit
//
//  Created by Bemacash on 19/11/19.
//  Copyright © 2019 Vinicius Valvassori. All rights reserved.
//

import UIKit

class SettingsTableViewCell: UITableViewCell {

    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var confirmSlider: UISlider!

    weak var sliderDelegate: SettingsSliderDelegate!

    @IBAction func valueChanged(_ sender: UISlider) {
        if sender.value > 0.9 {
            sliderDelegate.confirmSettingsChanged(slider: sender)
        }
        sender.value = 0.0
    }
}

protocol SettingsSliderDelegate: class {
    func confirmSettingsChanged(slider: UISlider)
}
