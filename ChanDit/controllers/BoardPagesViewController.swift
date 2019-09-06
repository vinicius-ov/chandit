//
//  ViewController.swift
//  ChanDit
//
//  Created by Vinicius Valvassori on 02/08/19.
//  Copyright © 2019 Vinicius Valvassori. All rights reserved.
//

import UIKit
import SnapKit

class BoardPagesViewController: UIViewController {
    
    @IBOutlet weak var postsTable: UITableView!
    var pageViewModel = PageViewModel() //deveria ser injetado
    
    var threadToLaunch: Int!
    var postNumberToNavigate: Int!
    
    var pickerView: UIPickerView!
    @IBOutlet weak var boardSelector: UITextField!
    let boardsViewModel = BoardsViewModel() //deveria ser injetado
    let service = Service() //deveria ser injetado
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        postsTable.dataSource = self
        postsTable.delegate = self
        postsTable.prefetchDataSource = self
        postsTable.rowHeight = UITableView.automaticDimension
        postsTable.estimatedRowHeight = 460
        postsTable.isHidden = true
        
        pickerView = UIPickerView()
        pickerView.delegate = self
        pickerView.dataSource = self
        boardSelector.inputView = pickerView
        
        //navigationController?.hidesBarsOnSwipe = true
        
        boardSelector.text = boardsViewModel.selectedBoardName
        
        let toolBar = UIToolbar()
        toolBar.barStyle = UIBarStyle.default
        toolBar.tintColor = UIColor.black
        toolBar.sizeToFit()
        
        let doneButton = UIBarButtonItem(title: "Done", style: UIBarButtonItem.Style.plain, target: self, action: #selector(hideKeyboard))
        let spaceButton = UIBarButtonItem(barButtonSystemItem: UIBarButtonItem.SystemItem.flexibleSpace, target: nil, action: nil)
        let cancelButton = UIBarButtonItem(title: "Cancel", style: UIBarButtonItem.Style.plain, target: self, action: #selector(hideKeyboardNoAction))
        
        toolBar.setItems([cancelButton, spaceButton, doneButton], animated: false)
        toolBar.isUserInteractionEnabled = true
        
        boardSelector.inputAccessoryView = toolBar
        
        fetchData(append: false)
        
    }
    
    func fetchData(append: Bool) {
        service.loadData(from: URL(string: "https://a.4cdn.org/\(boardsViewModel.selectedBoardId)/\(boardsViewModel.nextPage()).json")!) { (result) in
            switch result {
            case .success(let data):
                do {
                    guard let page = try? JSONDecoder().decode(Page.self, from: data) else {
                        print("error trying to convert data to JSON \(data)")
                        return
                    }
                    if append {
                        let threads:[ThreadViewModel] = page.threads.map ({ (thread: Thread) in
                            let tvm = ThreadViewModel.init(thread: thread)
                            return tvm
                        })
                        self.pageViewModel.threads.append(contentsOf: threads)
                    }else {
                        self.pageViewModel.threads = page.threads.map ({ (thread: Thread) in
                            let tvm = ThreadViewModel.init(thread: thread)
                            return tvm
                        })
                    }
                    DispatchQueue.main.async {
                        self.postsTable.reloadData()
                        self.postsTable.isHidden = false
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
        boardsViewModel.reset()
        postsTable.scrollToRow(at: IndexPath(row: 0, section: 0), at: .top, animated: false)
        fetchData(append: false)
    }
    
    @objc func hideKeyboardNoAction() {
        boardSelector.resignFirstResponder()
    }
    
    @objc func navigateToThreadView(_ sender: UIButton) {
        boardsViewModel.threadToLaunch = sender.tag
        navigateToThread()
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        threadToLaunch = nil
        postNumberToNavigate = nil
    }
    
    func navigateToThread() {
        performSegue(withIdentifier: "gotoThreadView", sender: self)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        let vc = segue.destination as! ThreadViewController
        let threadViewModel = ThreadViewModel(threadNumberToNavigate: boardsViewModel.threadToLaunch!, postNumberToNavigate: boardsViewModel.postNumberToNavigate!, originBoard: boardsViewModel.selectedBoardId)
        vc.threadViewModel = threadViewModel
    }
    
    @IBAction func reloadData(_ sender: Any) {
        postsTable.isHidden = true
        postsTable.scrollToRow(at: IndexPath(row: 0, section: 0), at: .top, animated: false)
        boardsViewModel.reset()
        fetchData(append: false)
    }
    
}

extension BoardPagesViewController : UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return pageViewModel.threads[section].posts.count
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return pageViewModel.threads.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        //if indexPath.row < pageViewModel.threads[indexPath.section].posts.count {
        let cell = tableView.dequeueReusableCell(withIdentifier: "postCell") as! PostTableViewCell
        let threadViewModel = pageViewModel.threads[indexPath.section]
        let post = threadViewModel.postViewModel(at: indexPath.row)
        cell.selectedBoardId = boardsViewModel.selectedBoardId
        cell.postViewModel = post
        
        cell.loadCell()
        
        cell.parentViewController = self
        
        cell.navigateToMessage = { (number: Int?) in
            self.boardsViewModel.postNumberToNavigate = number!
            self.boardsViewModel.threadToLaunch = threadViewModel.posts.first!.number!
            self.navigateToThread()
            print("will navigate")
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
        
        //pageViewModel.setNavigation(forThreadInSection section:Int, forPostInIndex index:Int)
        let threadToLaunch = pageViewModel.threadViewModel(at: section).postViewModel(at: 0).number
        viewThreadButton.tag = threadToLaunch!
        let selector = #selector(BoardPagesViewController.navigateToThreadView(_:))
        viewThreadButton.addTarget(self, action: selector, for: .touchUpInside)
        return view
    }
    
}

extension BoardPagesViewController : UITableViewDataSourcePrefetching {
    func tableView(_ tableView: UITableView, prefetchRowsAt indexPaths: [IndexPath]) {
        if indexPaths.contains([pageViewModel.threads.count-1,0]) {
            print("RELOAD!!!!")
            fetchData(append: true)
        }
    }
}

extension BoardPagesViewController: UIPickerViewDataSource, UIPickerViewDelegate {
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

