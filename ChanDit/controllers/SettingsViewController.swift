//
//  SettingsViewController.swift
//  ChanDit
//
//  Created by Bemacash on 19/11/19.
//  Copyright © 2019 Vinicius Valvassori. All rights reserved.
//

import UIKit

class SettingsViewController: UIViewController {

    @IBOutlet weak var tableVieww: UITableView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableVieww.register(UINib(nibName: "SettingsTableViewCell", bundle: nil),
        forCellReuseIdentifier: "cell")
        
        tableVieww.dataSource = self
    }
    
}

extension SettingsViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
        case 0: return 2
        case 1: return 1
        default: return 0
        }
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        switch section {
        case 0: return "Media Cache"
        case 1: return "Webm Sound"
        default: return ""
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell") as? SettingsTableViewCell
        cell?.titleLabel.text = "Clear Webm cache"
        return cell ?? UITableViewCell()
    }
    
    
}
