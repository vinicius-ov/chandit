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
    let mediaCacheOptions = ["Clear Image Cache", "Clear Webm Cache"]
    let optionsCategories = ["Media Cache", "Webm Audio"]
    let webmAudioOptions = ["Start muted"]

    override func viewDidLoad() {
        super.viewDidLoad()

        tableVieww.register(UINib(nibName: "SettingsTableViewCell", bundle: nil),
        forCellReuseIdentifier: "cell")
        tableVieww.register(UINib(nibName: "MultipleOptionsTableViewCell", bundle: nil),
        forCellReuseIdentifier: "cellOpts")

        tableVieww.dataSource = self
    }
}

extension SettingsViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
        case 0: return mediaCacheOptions.count
        case 1: return webmAudioOptions.count
        default: return 0
        }
    }

    func numberOfSections(in tableView: UITableView) -> Int {
        return optionsCategories.count
    }

    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return optionsCategories[section]
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if indexPath.section == 0 {
            let cell = tableView.dequeueReusableCell(withIdentifier: "cell") as? SettingsTableViewCell
            cell?.titleLabel.text = mediaCacheOptions[indexPath.row]
            cell?.confirmSlider.tag = indexPath.row
            cell?.sliderDelegate = self
            return cell ?? UITableViewCell()
        } else {
            let cell = tableView.dequeueReusableCell(withIdentifier: "cellOpts") as? MultipleOptionsTableViewCell
            cell?.titleLabel.text = webmAudioOptions[indexPath.row]
            return cell ?? UITableViewCell()
        }
    }
}

extension SettingsViewController: SettingsSliderDelegate {
    func confirmSettingsChanged(slider: UISlider) {
        if slider.tag == 0 {
            CacheManager.clearImageMemoryCache()
            CacheManager.clearImageDiskCache()
            self.showToast(message: "Image cache cleared!")
        } else if slider.tag == 1 {
//            CacheManager.clearWebmCache()
            CacheManager.removeWebmCache()
            showToast(message: "Webm cache cleared!")
        }
    }
}
