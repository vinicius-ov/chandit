//
//  ViewController.swift
//  ChanDit
//
//  Created by Vinicius Valvassori on 02/08/19.
//  Copyright © 2019 Vinicius Valvassori. All rights reserved.
//

import UIKit

protocol CellTapInteractionDelegate: class {
    func linkTapped(postNumber: Int, opNumber: Int, originNumber: Int)
    func imageTapped(_ viewController: UIViewController)
    func presentAlertExitingApp(_ actions: [UIAlertAction])
}

class BaseViewController: UIViewController {
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        get {
            return .portrait
        }
    }
}

class BoardPagesViewController: BaseViewController {
    @IBOutlet weak var postsTable: UITableView!
    var pageViewModel = PageViewModel() //deveria ser injetado
    
    var pickerView: UIPickerView!
    @IBOutlet weak var boardSelector: UITextField!
    let boardsViewModel = BoardsViewModel() //deveria ser injetado
    let service = Service() //deveria ser injetado
    var lastModified: String?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        postsTable.dataSource = self
        postsTable.delegate = self
        postsTable.prefetchDataSource = self
        postsTable.rowHeight = UITableView.automaticDimension
        postsTable.estimatedRowHeight = 400
        postsTable.isHidden = true
        
        pickerView = UIPickerView()
        pickerView.delegate = self
        pickerView.dataSource = self
        boardSelector.inputView = pickerView
        boardSelector.isEnabled = false
        boardSelector.tintColor = .clear
        
        postsTable.register(UINib(nibName: "PostCell", bundle: nil), forCellReuseIdentifier: "postCellIdentifier")
        postsTable.register(UINib(nibName: "ThreadFooterView", bundle: nil), forHeaderFooterViewReuseIdentifier: ThreadFooterView.reuseIdentifier)
        
        let toolBar = UIToolbar()
        toolBar.barStyle = UIBarStyle.default
        toolBar.tintColor = UIColor.black
        toolBar.sizeToFit()
        
        let doneButton = UIBarButtonItem(
            title: "Done",
            style: UIBarButtonItem.Style.plain,
            target: self,
            action: #selector(didSelectBoardFromPicker))
        let spaceButton = UIBarButtonItem(
            barButtonSystemItem: UIBarButtonItem.SystemItem.flexibleSpace,
            target: nil, action: nil)
        let cancelButton = UIBarButtonItem(
            title: "Cancel",
            style: UIBarButtonItem.Style.plain, target: self,
            action: #selector(hideKeyboardNoAction))
        cancelButton.tintColor = .white
        doneButton.tintColor = .white
        
        toolBar.setItems([cancelButton, spaceButton, doneButton], animated: false)
        toolBar.isUserInteractionEnabled = true
        
        boardSelector.inputAccessoryView = toolBar
        
        fetchBoards()
        
        
        
    }
    
    func fetchData(append: Bool) {
        let url = URL(string: "https://a.4cdn.org/\(boardsViewModel.selectedBoardId!)/\(boardsViewModel.nextPage()).json")
        service.loadData(from: url!, lastModified: lastModified) { (result) in
            switch result {
            case .success(let response):
                self.lastModified =  response.modified
                do {
                    guard let page = try? JSONDecoder().decode(Page.self, from: response.data) else {
                        print("error trying to convert data to JSON \(response)")
                        return
                    }
                    let threads: [ThreadViewModel] = page.threads.map({ (thread: Thread) in
                        let tvm = ThreadViewModel.init(thread: thread)
                        return tvm
                    })
                        self.pageViewModel.threads.addObjects(from: threads)
                    DispatchQueue.main.async {
                        self.pickerView.selectRow(self.boardsViewModel.getCurrentBoardIndex() ?? 0,
                                                  inComponent: 0,
                                                  animated: true)
                        self.postsTable.isHidden = false
                        self.boardSelector.isEnabled = true
                        self.postsTable.reloadData()
                        if !append {
                            self.postsTable.scrollToRow(at: IndexPath(row: 0, section: 0), at: .top, animated: false)
                        }
                    }
                }
            case .failure(let error):
                self.callAlertView(title: "Fetch failed",
                                   message: "Failed to load board threads. Try again. \(error?.localizedDescription)", actions: [])
            }
        }
    }
    
    func fetchBoards() {
        service.loadData(from: URL(string: "https://a.4cdn.org/boards.json")!, lastModified: lastModified) { (result) in
            switch result {
            case .success(let result):
                do {
                    guard let boards = try? JSONDecoder().decode(Boards.self, from: result.data) else {
                        print("BOARDS error trying to convert data to JSON \(result)")
                        return
                    }
                    self.boardsViewModel.boards = boards.boards!.sorted()
                    DispatchQueue.main.async {
                        self.boardSelector.text = self.boardsViewModel.selectedBoardName
                    }
                    self.fetchData(append: false)
                }
            case .failure(let error):
                self.callAlertView(title: "Fetch failed",
                                   message: "Failed to load board lista. Try reloading the app. \(error?.localizedDescription)", actions: [])
            }
        }
    }
    
    @objc func didSelectBoardFromPicker() {
        boardSelector.resignFirstResponder()
        updateBoardSelector()
    }
    
    func updateBoardSelector() {
        postsTable.isHidden = true
        let index = pickerView.selectedRow(inComponent: 0)
        let title = boardsViewModel.completeBoardName(atRow: index)
        boardSelector.text = title
        boardsViewModel.setCurrentBoard(byIndex: index)
        boardsViewModel.reset()
        pageViewModel.threads.removeAllObjects()
        lastModified = nil
        fetchData(append: false)
    }
    
    @objc func hideKeyboardNoAction() {
        boardSelector.resignFirstResponder()
        boardSelector.text = boardsViewModel.currentBoard?.title
    }
    
    @objc func navigateToThreadView(_ sender: UIButton) {
        boardsViewModel.threadToLaunch = sender.tag
        navigateToThread()
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        boardsViewModel.resetNavigation()
    }
    
    func navigateToThread() {
        performSegue(withIdentifier: "gotoThreadView", sender: self)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        let viewController = segue.destination as? ThreadViewController
        let threadViewModel = ThreadViewModel(
            threadNumberToNavigate: boardsViewModel.threadToLaunch!,
            postNumberToNavigate: boardsViewModel.postNumberToNavigate,
            originBoard: boardsViewModel.selectedBoardId, completeBoardName: boardsViewModel.completeBoardName(atRow: pickerView.selectedRow(inComponent: 0)))
        viewController?.threadViewModel = threadViewModel
    }
    
    @IBAction func reloadData(_ sender: Any) {
        print(pageViewModel.threads.count)
        postsTable.isHidden = true
        pageViewModel.threads.removeAllObjects()
        boardsViewModel.reset()
        fetchData(append: false)
    }
    
    @IBAction func gotoTop(_ sender: Any) {
        self.postsTable.scrollToRow(at:
            IndexPath(item: 0, section: 0), at: .top, animated: true)
    }
}

extension BoardPagesViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        guard let threadViewModel = pageViewModel.threads[section] as? ThreadViewModel else { return 0 }
        return threadViewModel.posts.count
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return pageViewModel.threads.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "postCellIdentifier") as? PostTableViewCell
        let threadViewModel = pageViewModel.threads[indexPath.section]
        
        let postViewModel = (threadViewModel as? ThreadViewModel)?.postViewModel(at: indexPath.row)
        cell?.boardName = boardsViewModel.completeBoardName(atRow: pickerView.selectedRow(inComponent: 0))
        cell?.selectedBoardId = boardsViewModel.selectedBoardId
        cell?.postViewModel = postViewModel
        
        cell?.loadCell()
        cell?.tapDelegate = self
                
        return cell ?? UITableViewCell()
    }
    
    func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        let footerView = tableView.dequeueReusableHeaderFooterView(withIdentifier: "ThreadFooterView") as? ThreadFooterView

        guard let threadToLaunch = pageViewModel.threadViewModel(at: section)?.postViewModel(at: 0) else {
            return footerView
        }

        footerView?.threadToNavigate = threadToLaunch.number
        footerView?.imagesCount.text = "\(threadToLaunch.images ?? 0) (\(threadToLaunch.omittedImages ?? 0))"
        footerView?.postsCount.text = "\(threadToLaunch.replies ?? 0) (\(threadToLaunch.omittedPosts ?? 0))"
        footerView?.delegate = self
        footerView?.closedIcon.isHidden = !threadToLaunch.isClosed

        return footerView
    }
}

extension BoardPagesViewController: UITableViewDataSourcePrefetching {
    func tableView(_ tableView: UITableView, prefetchRowsAt indexPaths: [IndexPath]) {
        if indexPaths.contains([pageViewModel.threads.count-1, 0]) {
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
        return boardsViewModel.completeBoardName(atRow: row)
    }
}

extension BoardPagesViewController: CellTapInteractionDelegate {
    func linkTapped(postNumber: Int, opNumber: Int, originNumber: Int) {
        self.boardsViewModel.postNumberToNavigate = postNumber
        self.boardsViewModel.threadToLaunch = opNumber
        self.navigateToThread()
    }
    
    func presentAlertExitingApp(_ actions: [UIAlertAction]) {
        callAlertView(
            title: "Exit ChanDit",
            message: "This link will take you outside ChanDit. You are in your own. Proceed?",
            actions: actions)
    }
    
    func imageTapped(_ viewController: UIViewController) {
        show(viewController, sender: self)
    }
    
}

extension BoardPagesViewController: ThreadFooterViewDelegate {
    func threadFooterView(_ footer: ThreadFooterView, threadToNavigate section: Int) {
        self.boardsViewModel.threadToLaunch = footer.threadToNavigate
        self.navigateToThread()
    }
}

