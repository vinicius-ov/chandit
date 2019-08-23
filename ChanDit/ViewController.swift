//
//  ViewController.swift
//  ChanDit
//
//  Created by Vinicius Valvassori on 02/08/19.
//  Copyright © 2019 Vinicius Valvassori. All rights reserved.
//

import UIKit

class ViewController: UIViewController {
    
    @IBOutlet weak var postsTable: UITableView!
    var pageViewModel = PageViewModel()
    var threadToLaunch:Int!
    var pickerView: UIPickerView!
    @IBOutlet weak var boardSelector: UITextField!
    let boards = ["Vydia","Vydia Generals"]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        postsTable.dataSource = self
        postsTable.delegate = self
        postsTable.rowHeight = UITableView.automaticDimension
        postsTable.estimatedRowHeight = 400
        
        pickerView = UIPickerView()
        pickerView.delegate = self
        pickerView.dataSource = self
        boardSelector.inputView = pickerView
        boardSelector.text = boards[0]
        
        let toolBar = UIToolbar()
        toolBar.barStyle = UIBarStyle.default
        toolBar.tintColor = UIColor.black
        toolBar.sizeToFit()
        
        let doneButton = UIBarButtonItem(title: "Done", style: UIBarButtonItem.Style.plain, target: self, action: #selector(hideKeyboard))
        let spaceButton = UIBarButtonItem(barButtonSystemItem: UIBarButtonItem.SystemItem.flexibleSpace, target: nil, action: nil)
        let cancelButton = UIBarButtonItem(title: "Cancel", style: UIBarButtonItem.Style.plain, target: self, action: #selector(hideKeyboard))
        
        toolBar.setItems([cancelButton, spaceButton, doneButton], animated: false)
        toolBar.isUserInteractionEnabled = true
        
        boardSelector.inputAccessoryView = toolBar
    }
    
    override func motionEnded(_ motion: UIEvent.EventSubtype, with event: UIEvent?){
        if motion == .motionShake
        {
            postsTable.reloadData()
        }
    }
    
    @objc func hideKeyboard() {
         boardSelector.resignFirstResponder()
    }
    
    override func viewDidLayoutSubviews() {
//        print(postImage.frame.width)
//        print(self.view.bounds.width)
        let service = Service()
        service.loadData(from: URL(string: "https://a.4cdn.org/v/1.json")!) { (result) in
            switch result {
            case .success(let data):
                do {
                    guard let page = try? JSONDecoder().decode(Page.self, from: data) else {
                            print("error trying to convert data to JSON \(data)")
                            return
                    }
                    self.pageViewModel.threads = page.threads.map ({ (thread: Thread) in
                        let tvm = ThreadViewModel.init(thread: thread)
                        return tvm
                    })
                    
                    DispatchQueue.main.async {
                        self.postsTable.reloadData()
                    }
                }
                break
            case .failure(let error):
                break
            }
        }
    }
    
    @objc func navigateToThreadView() {
        performSegue(withIdentifier: "gotoThreadView", sender: self)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        let vc = segue.destination as! ThreadViewController
        vc.threadNumber = threadToLaunch
    }
    
}

extension ViewController : UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return pageViewModel.threads[section].posts.count + 1
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return pageViewModel.threads.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if indexPath.row < pageViewModel.threads[indexPath.section].posts.count {
            let cell = tableView.dequeueReusableCell(withIdentifier: "postCell") as! PostTableViewCell
            let thread = pageViewModel.threads[indexPath.section]
            let post = thread.postViewModel(at: indexPath.row)
            cell.postViewModel = post
            cell.loadCell()
            return cell
        } else {
            let cell = tableView.dequeueReusableCell(withIdentifier: "viewThreadCell") as! ViewThreadTableViewCell
            cell.viewThread.addTarget(self, action: #selector(ViewController.navigateToThreadView), for: .touchUpInside)
            threadToLaunch = pageViewModel.threadViewModel(at: indexPath.section).postViewModel(at: 0).number
            
            return cell
        }
    }
    
}

extension ViewController: UIPickerViewDataSource, UIPickerViewDelegate {
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return boards.count
    }
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return boards[row]
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        boardSelector.text = boards[row]
    }
}
