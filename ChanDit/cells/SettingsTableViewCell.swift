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
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        
        // Configure the view for the selected state
    }
    
    @IBAction func valueChanged(_ sender: UISlider) {
        print(sender.value)
        if sender.value > 0.9 {
            sliderDelegate.confirmSettingsChanged(slider: sender)
        }
        UIView.animate(withDuration: 1.25, animations: {
            sender.value = 0.0
        })
    }
}

protocol SettingsSliderDelegate: class {
    func confirmSettingsChanged(slider: UISlider)
}
