//
//  ViewController.swift
//  ChanDit
//
//  Created by Vinicius Valvassori on 02/08/19.
//  Copyright © 2019 Vinicius Valvassori. All rights reserved.
//

import UIKit

protocol CellTapInteractionDelegate: class {
    func linkTapped(postNumber: Int, opNumber: Int)
    func imageTapped(_ viewController: UIViewController)
    func presentAlertExitingApp(_ actions: [UIAlertAction])
}

class BaseViewController: UIViewController {
    override var shouldAutorotate: Bool {
        get {
            return false
        }
    }
    
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
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        postsTable.dataSource = self
        postsTable.delegate = self
        postsTable.prefetchDataSource = self
        postsTable.rowHeight = UITableView.automaticDimension
        postsTable.estimatedRowHeight = 260
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
        
        let doneButton = UIBarButtonItem(title: "Done", style: UIBarButtonItem.Style.plain, target: self, action: #selector(didSelectBoardFromPicker))
        let spaceButton = UIBarButtonItem(barButtonSystemItem: UIBarButtonItem.SystemItem.flexibleSpace, target: nil, action: nil)
        let cancelButton = UIBarButtonItem(title: "Cancel", style: UIBarButtonItem.Style.plain, target: self, action: #selector(hideKeyboardNoAction))
        cancelButton.tintColor = .white
        doneButton.tintColor = .white
        
        toolBar.setItems([cancelButton, spaceButton, doneButton], animated: false)
        toolBar.isUserInteractionEnabled = true
        
        let swipeToTop = UISwipeGestureRecognizer(target: self, action: #selector(scrollToTop))
        swipeToTop.direction = .down
        swipeToTop.numberOfTouchesRequired = 2
        postsTable.addGestureRecognizer(swipeToTop)
        
        boardSelector.inputAccessoryView = toolBar
        
        fetchBoards()
    }
    
    @objc
    func scrollToTop() {
        print("poqw")
    }
    
    func fetchData(append: Bool) {
        let url = URL(string: "https://a.4cdn.org/\(boardsViewModel.selectedBoardId!)/\(boardsViewModel.nextPage()).json")
        service.loadData(from: url!) { (result) in
            switch result {
            case .success(let data):
                do {
                    guard let page = try? JSONDecoder().decode(Page.self, from: data) else {
                        print("error trying to convert data to JSON \(data)")
                        return
                    }
                    let threads:[ThreadViewModel] = page.threads.map ({ (thread: Thread) in
                        let tvm = ThreadViewModel.init(thread: thread)
                        return tvm
                    })
                        self.pageViewModel.threads.addObjects(from: threads)
                    DispatchQueue.main.async {
                        self.postsTable.reloadData()
                        if !append {
                            self.postsTable.scrollToRow(at: IndexPath(row: 0, section: 0), at: .top, animated: false)
                        }
                        self.postsTable.isHidden = false
                        self.pickerView.selectRow(self.boardsViewModel.getCurrentBoardIndex() ?? 0,
                                                  inComponent: 0,
                                                  animated: true)
                        self.boardSelector.isEnabled = true
                    }
                }
                break
            case .failure(_):
                break
            }
        }
    }
    
    func fetchBoards() {
        service.loadData(from: URL(string: "https://a.4cdn.org/boards.json")!) { (result) in
            switch result {
            case .success(let data):
                do {
                    guard let boards = try? JSONDecoder().decode(Boards.self, from: data) else {
                        print("BOARDS error trying to convert data to JSON \(data)")
                        return
                    }
                    self.boardsViewModel.boards = boards.boards!.sorted()
                    DispatchQueue.main.async {
                        self.boardSelector.text = self.boardsViewModel.selectedBoardName
                    }
                    self.fetchData(append: false)
                }
                break
            case .failure(_):
                break
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
        let vc = segue.destination as! ThreadViewController
        let threadViewModel = ThreadViewModel(threadNumberToNavigate: boardsViewModel.threadToLaunch!, postNumberToNavigate: boardsViewModel.postNumberToNavigate, originBoard: boardsViewModel.selectedBoardId)
        vc.threadViewModel = threadViewModel
    }
    
    @IBAction func reloadData(_ sender: Any) {
        print(pageViewModel.threads.count)
        postsTable.isHidden = true
        pageViewModel.threads.removeAllObjects()
        boardsViewModel.reset()
        fetchData(append: false)
    }
    
}

extension BoardPagesViewController : UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return (pageViewModel.threads[section] as! ThreadViewModel).posts.count
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return pageViewModel.threads.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "postCellIdentifier") as! PostTableViewCell
        let threadViewModel = pageViewModel.threads[indexPath.section]
        let post = (threadViewModel as! ThreadViewModel).postViewModel(at: indexPath.row)
        cell.selectedBoardId = boardsViewModel.selectedBoardId
        cell.postViewModel = post
        
        cell.loadCell()
        cell.tapDelegate = self
                
        return cell
    }
    
    func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        
        let footerView = tableView.dequeueReusableHeaderFooterView(withIdentifier: "ThreadFooterView") as! ThreadFooterView
        
        guard let threadToLaunch = pageViewModel.threadViewModel(at: section).postViewModel(at: 0) else {
            return footerView
        }
        
        footerView.threadToNavigate = threadToLaunch.number
        footerView.imagesCount.text = "\(threadToLaunch.images ?? 0) (\(threadToLaunch.omittedImages ?? 0))"
        footerView.postsCount.text = "\(threadToLaunch.replies ?? 0) (\(threadToLaunch.omittedPosts ?? 0))"
        footerView.delegate = self
        
        return footerView
    }
    
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        let cell = tableView.dequeueReusableCell(withIdentifier: "postCellIdentifier") as! PostTableViewCell
        let threadViewModel = pageViewModel.threads[indexPath.section]
        let post = (threadViewModel as! ThreadViewModel).postViewModel(at: indexPath.row)
        cell.postText.set(html: post?.comment)
    }
}

extension BoardPagesViewController : UITableViewDataSourcePrefetching {
    func tableView(_ tableView: UITableView, prefetchRowsAt indexPaths: [IndexPath]) {
        if indexPaths.contains([pageViewModel.threads.count-3,0]) {
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
    func linkTapped(postNumber: Int, opNumber: Int) {
        self.boardsViewModel.postNumberToNavigate = postNumber
        self.boardsViewModel.threadToLaunch = opNumber
        self.navigateToThread()
    }
    
    func presentAlertExitingApp(_ actions: [UIAlertAction]) {
        callAlertView(title: "Exit ChanDit", message: "This link will take you outside ChanDit. You are in your own. Proceed?", actions: actions)
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
