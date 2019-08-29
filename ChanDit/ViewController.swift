//
//  ViewController.swift
//  ChanDit
//
//  Created by Vinicius Valvassori on 02/08/19.
//  Copyright © 2019 Vinicius Valvassori. All rights reserved.
//

import UIKit
import SnapKit

class ViewController: UIViewController {
    
    @IBOutlet weak var postsTable: UITableView!
    var pageViewModel = PageViewModel() //deveria ser injetado
    var threadToLaunch:Int!
    var pickerView: UIPickerView!
    @IBOutlet weak var boardSelector: UITextField!
    let boardsViewModel = BoardsViewModel() //deveria ser injetado
    let service = Service() //deveria ser injetado
    
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
        
        boardSelector.text = boardsViewModel.selectedBoardName
        
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
        
        fetchData()
        
    }
    
    func fetchData() {
        service.loadData(from: URL(string: "https://a.4cdn.org/\(boardsViewModel.selectedBoardId)/1.json")!) { (result) in
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
    
    #if DEBUG
    override func motionEnded(_ motion: UIEvent.EventSubtype, with event: UIEvent?){
        if motion == .motionShake
        {
            postsTable.reloadData()
        }
    }
    #endif
    
    @objc func hideKeyboard() {
        boardSelector.resignFirstResponder()
        postsTable.scrollToRow(at: IndexPath(row: 0, section: 0), at: .top, animated: false)
        fetchData()
    }
    
    @objc func navigateToThreadView(_ sender: UIButton) {
        self.threadToLaunch = sender.tag
        performSegue(withIdentifier: "gotoThreadView", sender: self)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        let vc = segue.destination as! ThreadViewController
        vc.threadNumber = self.threadToLaunch
        vc.selectedBoardId = boardsViewModel.selectedBoardId
    }
    
}

extension ViewController : UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return pageViewModel.threads[section].posts.count
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return pageViewModel.threads.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        //if indexPath.row < pageViewModel.threads[indexPath.section].posts.count {
        let cell = tableView.dequeueReusableCell(withIdentifier: "postCell") as! PostTableViewCell
        let thread = pageViewModel.threads[indexPath.section]
        let post = thread.postViewModel(at: indexPath.row)
        cell.selectedBoardId = boardsViewModel.selectedBoardId
        cell.postViewModel = post
        
        cell.loadCell()
        
        cell.parentViewController = self
        
        cell.imageViewSelector = { tapGesture in
            let viewController:UIViewController = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "ImageViewerViewController") as UIViewController
            self.present(viewController, animated: true, completion: nil)
        }
        
        return cell
        
    }
    
    func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        let view = UIView()
        view.backgroundColor = .darkGray
        let viewThreadButton = UIButton()
        
        viewThreadButton.setTitle("View Thread", for: .normal)
        viewThreadButton.backgroundColor = .gray
        viewThreadButton.setTitleColor(.white, for: .normal)
        viewThreadButton.sizeToFit()
        view.addSubview(viewThreadButton)
        
        viewThreadButton.snp.makeConstraints { (make) -> Void in
            make.centerY.equalTo(view)
            make.trailing.equalTo(-10)
            make.width.equalTo(120)
        }
        
        let threadToLaunch = pageViewModel.threadViewModel(at: section).postViewModel(at: 0).number
        viewThreadButton.tag = threadToLaunch!
        let selector = #selector(ViewController.navigateToThreadView(_:))
        viewThreadButton.addTarget(self, action: selector, for: .touchUpInside)
        return view
    }
    
}

extension ViewController: UIPickerViewDataSource, UIPickerViewDelegate {
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return boardsViewModel.boards.count
    }
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return boardsViewModel.boards[row].name
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        let name = boardsViewModel.boards[row].name
        boardSelector.text = name
        boardsViewModel.setCurrentBoard(byBoardName: name)
    }
    
}

