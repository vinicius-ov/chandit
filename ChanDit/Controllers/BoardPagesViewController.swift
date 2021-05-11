//
//  ViewController.swift
//  ChanDit
//
//  Created by Vinicius Valvassori on 02/08/19.
//  Copyright © 2019 Vinicius Valvassori. All rights reserved.
//  swiftlint:disable trailing_whitespace

import UIKit

class BaseViewController: UIViewController {
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return .portrait
    }
}

class BoardPagesViewController: BaseViewController {
    @IBOutlet weak var postsTable: UITableView!
    @IBOutlet weak var boardSelector: UITextField!
    @IBOutlet weak var reloadActivityView: UIActivityIndicatorView!
    @IBOutlet weak var reloadMessage: UILabel!

    var pageViewModel: PageViewModel = PageViewModel(threads: Array()) //deveria ser injetado
    var pickerView: UIPickerView!
    let boardsViewModel: BoardsViewModel = BoardsViewModel() //deveria ser injetado
    let service: Service = Service() //deveria ser injetado
    var lastModified: String?
    var catalogMode: Bool = false

    private func registerCellViews() {
        postsTable.register(
            UINib(nibName: "PostCell",
                  bundle: nil),
            forCellReuseIdentifier: "postCellIdentifier")
        postsTable.register(
        UINib(nibName: "PostCellHidden",
              bundle: nil),
        forCellReuseIdentifier: "postCell_Hidden_Identifier")
        postsTable.register(
            UINib(nibName: "ThreadFooterView",
                  bundle: nil),
            forHeaderFooterViewReuseIdentifier: ThreadFooterView.reuseIdentifier)
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        postsTable.dataSource = self
        postsTable.delegate = self
        postsTable.prefetchDataSource = self

        postsTable.rowHeight = UITableView.automaticDimension
        postsTable.estimatedRowHeight = 200

        postsTable.isHidden = true
        
        pickerView = UIPickerView()
        pickerView.delegate = self
        pickerView.dataSource = self
        boardSelector.inputView = pickerView
        boardSelector.isEnabled = false
        boardSelector.tintColor = .clear
        
        registerCellViews()

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

        self.reloadActivityView.isHidden = false
        self.reloadMessage.isHidden = true

        fetchBoards()
    }

    func fetchData(append: Bool) {
        guard let selectedBoard = boardsViewModel.selectedBoardId else {
            fetchBoards()
            return
        }

        let url = URL(string: "https://a.4cdn.org/\(selectedBoard)/\(boardsViewModel.nextPage()).json")
        service.loadData(from: url!, lastModified: !append ? lastModified : nil) { (result) in
            switch result {
            case .success(let response):
                switch response.code {
                case 200..<300:
                    if !append {
                        self.pageViewModel.threads.removeAll()
                    } else {
                        DispatchQueue.main.async {
                        self.reloadActivityView.isHidden = true
                        self.reloadMessage.isHidden = true
                        }
                    }
                    self.lastModified = response.modified
                    do {
                        guard let page = try? JSONDecoder().decode(Page.self, from: response.data) else {
                            print("error trying to convert data to JSON \(response)")
                            return
                        }

                        page.threads.forEach {
                            let tvm: ThreadViewModel = ThreadViewModel(thread: $0)
                            if self.pageViewModel.canAppend(thread: tvm) {
                                self.pageViewModel.threads.append(tvm)
                            }
                        }

                        DispatchQueue.main.async {
                            self.boardSelector.isEnabled = true
                            self.postsTable.reloadData()
                            if !append {
                                self.postsTable.scrollToRow(at: IndexPath(row: 0, section: 0),
                                                            at: .top, animated: false)
                            }
                        }
                    }
                case 300..<400:
                    DispatchQueue.main.async {
                        self.showToast(message: "No new threads")
                    }
                default:
                    self.showAlertView(title: "Fetch failed",
                    message: "Failed to load board threads. Try again.",
                    actions: [])
                }
                DispatchQueue.main.async {
                    self.postsTable.isHidden = false
                }
            case .failure(let error):
                self.showAlertView(title: "Fetch failed",
                                   message: "Failed to load board threads. Try again. \(error.localizedDescription)",
                    actions: [])
                DispatchQueue.main.async {
                self.reloadActivityView.isHidden = true
                self.reloadMessage.isHidden = false
                }
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
                        self.pickerView.selectRow(self.boardsViewModel.getCurrentBoardIndex() ?? 0,
                        inComponent: 0,
                        animated: true)
                    }
                    self.fetchData(append: false)
                }
            case .failure(let error):
                self.showAlertView(title: "Fetch failed",
                                   message: "Failed to load board lista. "
                    + "Try reloading the app. \(error.localizedDescription)",
                    actions: [])
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
        pageViewModel.threads.removeAll()
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

    override func viewWillAppear(_ animated: Bool) {
        navigationController?.navigationBar.isHidden = false
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        let viewController = segue.destination as? ThreadViewController
        let threadViewModel = ThreadViewModel(
            threadNumberToNavigate: boardsViewModel.threadToLaunch!,
            postNumberToNavigate: boardsViewModel.postNumberToNavigate,
            originBoard: boardsViewModel.selectedBoardId,
            completeBoardName: boardsViewModel.completeBoardName(atRow: pickerView.selectedRow(inComponent: 0)))
        viewController?.threadViewModel = threadViewModel
    }

    @IBAction func reloadData(_ sender: Any) {
        postsTable.isHidden = true
        self.boardsViewModel.reset()
        fetchData(append: false)
    }

    @IBAction func gotoTop(_ sender: Any) {
//        self.postsTable.scrollToRow(at: IndexPath(item: 0, section: 0),
//                                    at: .top, animated: true)
        catalogMode = !catalogMode
        postsTable.reloadData()
    }

    @IBAction func gotoNewThreadWebView(_ sender: Any) {
        let webVC = SwiftWebVC(urlString: "https://www.4chan.org/\(boardsViewModel.selectedBoardId ?? "a")/",
            sharingEnabled: false)
        show(webVC, sender: self)
    }

    @IBAction func goSettings(_ sender: Any) {
        let settings = SettingsViewController(nibName: "SettingsViewController", bundle: nil)
        show(settings, sender: self)
    }
}

extension BoardPagesViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if sectionShouldBeHidden(section) {
            return 0 // Don't show any rows for hidden sections
        } else if catalogMode {
            return 1
        } else {
            let threadViewModel = pageViewModel.threads[section]
            return threadViewModel.posts.count
        }
    }

    func numberOfSections(in tableView: UITableView) -> Int {
        return pageViewModel.threads.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {

        let threadViewModel: ThreadViewModel = pageViewModel.threads[indexPath.section]

        guard let postViewModel: PostViewModel = threadViewModel.postViewModel(at: indexPath.row)
        else { return UITableViewCell() }

        let cell: PostTableViewCell?

        if postViewModel.isHidden {
            cell = tableView.dequeueReusableCell(withIdentifier: "postCell_Hidden_Identifier") as? PostTableViewCell
        } else {
            cell = tableView.dequeueReusableCell(withIdentifier: "postCellIdentifier") as? PostTableViewCell
        }

        cell?.setupCell(threadViewModel: threadViewModel, postViewModel: postViewModel,
                        currentBoard: boardsViewModel.selectedBoardId ?? "",
                        tapDelegate: self, toastDelegate: self, hideDelegate: self)
        
        cell?.setupPostHeader()
        cell?.loadCell()

        return cell ?? UITableViewCell()

    }
    
    func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        let footerView = tableView.dequeueReusableHeaderFooterView(
            withIdentifier: "ThreadFooterView") as? ThreadFooterView

        guard let threadVM = pageViewModel.threadViewModel(at: section),
            let threadToLaunch = threadVM.postViewModel(at: 0) else {
            return footerView
        }
        
        footerView?.threadIsVisible = threadVM.isHidden
        footerView?.section = section
        footerView?.threadToNavigate = threadToLaunch.number
        footerView?.imagesCount.text = "\(threadToLaunch.images ?? 0) (\(threadToLaunch.omittedImages ?? 0))"
        footerView?.postsCount.text = "\(threadToLaunch.replies ?? 0) (\(threadToLaunch.omittedPosts ?? 0))"
        footerView?.delegate = self
        footerView?.closedIcon.isHidden = !threadToLaunch.isClosed

        return footerView
    }

    func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath) -> [UITableViewRowAction]? {

        let reportAction = UITableViewRowAction(style: .normal, title: "Report") { (rowAction, indexPath) in
            //TODO: edit the row at indexPath here
        }
        reportAction.backgroundColor = .red

        let hideAction = UITableViewRowAction(style: .normal, title: "Show/Hide") { (_, indexPath) in
            let threadViewModel: ThreadViewModel = self.pageViewModel.threads[indexPath.section]
            guard let postViewModel = threadViewModel.postViewModel(at: indexPath.row) else { return }
            
            if postViewModel.isOp {
                threadViewModel.toggleHidden()
            } else {
                postViewModel.toggleHidden()
            }
            self.postsTable.reloadData()
        }
        hideAction.backgroundColor = .blue

        return [hideAction]
    }

    private func sectionShouldBeHidden(_ section: Int) -> Bool {
        let threadViewModel = pageViewModel.threads[section]
        return threadViewModel.isHidden
    }
}

extension BoardPagesViewController: UITableViewDataSourcePrefetching {
    func tableView(_ tableView: UITableView, prefetchRowsAt indexPaths: [IndexPath]) {
        print(indexPaths)
        if indexPaths.contains([pageViewModel.threads.count-5, 0]) {
            //toggleActivityLoaderVisibility()
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

        if opNumber == 0 {
            self.boardsViewModel.threadToLaunch = postNumber
        } else {
            self.boardsViewModel.threadToLaunch = opNumber
        }

        self.navigateToThread()
    }
    
    func presentAlertExitingApp(_ actions: [UIAlertAction]) {
        showAlertView(
            title: "Exit ChanDit",
            message: "This link will take you outside ChanDit. You are in your own. Proceed?",
            actions: actions)
    }
    
    func imageTapped(_ viewController: UIViewController) {
        show(viewController, sender: self)
    }
    
}

extension BoardPagesViewController: ThreadFooterViewDelegate {
    func toggleVisibility(section: Int) {
        guard let threadVM = pageViewModel.threadViewModel(at: section) else { return }
        threadVM.toggleHidden()
        postsTable.reloadData()
    }

    func threadFooterView(_ footer: ThreadFooterView, threadToNavigate section: Int) {
        self.boardsViewModel.threadToLaunch = footer.threadToNavigate
        self.navigateToThread()
    }
}

extension BaseViewController: ToastDelegate {
    func showToast(flagHint: String) {
        self.showToast(message: flagHint,
                       textColor: .white,
                       backgroundColor: .darkGray)
    }

    func showToastForCopy(text: String) {
        self.showToast(message: text,
                       textColor: .black,
                       backgroundColor: .green)
    }
}

extension BoardPagesViewController: HideDelegate {
    func hidePost(number: Int) {
        print("hide post \(number)")
    }

    func hideThread(number: Int) {
        print("hide thread \(number)")
        postsTable.isEditing = true
    }
}
