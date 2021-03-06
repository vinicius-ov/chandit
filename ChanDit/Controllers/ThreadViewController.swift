//
//  ThreadViewController.swift
//  ChanDit
//
//  Created by Vinicius Valvassori on 23/08/19.
//  Copyright © 2019 Vinicius Valvassori. All rights reserved.
//  swiftlint:disable trailing_whitespace

import UIKit

class ThreadViewController: BaseViewController {
    var threadViewModel: ThreadViewModel!
    var threadNumber: Int!
    var postNumberToReturn = [Int]()
    var selectedBoardId: String!
    let service = Service()
    var lastModified: String?
    var indexPathNav: IndexPath!
    
    @IBOutlet weak var postsTable: UITableView!
    @IBOutlet weak var reloadButton: UIBarButtonItem!

    @IBOutlet weak var loadingIndicator: UIActivityIndicatorView!

    override func viewDidLoad() {
        super.viewDidLoad()
        postsTable.isHidden = true
        postsTable.dataSource = self
        postsTable.delegate = self

        postsTable.register(UINib(nibName: "PostCell", bundle: nil),
                            forCellReuseIdentifier: "postCellIdentifier")
        postsTable.register(
        UINib(nibName: "PostCellNoImage", bundle: nil),
                            forCellReuseIdentifier: "postCell_NoImage_Identifier")
        postsTable.register(
        UINib(nibName: "PostCellHidden",
              bundle: nil),
        forCellReuseIdentifier: "postCell_Hidden_Identifier")
        postsTable.register(UINib(nibName: "ThreadFooterView", bundle: nil),
                            forHeaderFooterViewReuseIdentifier: ThreadFooterView.reuseIdentifier)
    
        postsTable.rowHeight = UITableView.automaticDimension
        postsTable.estimatedRowHeight = 200

        fetchData()
    }

    private func fetchData(refreshing: Bool = false) {
        guard let board = threadViewModel.boardIdToNavigate,
            let opNumber = threadViewModel.threadNumberToNavigate
            else {
                self.showAlertView(title: "Fetch failed",
                message: "Failed to load thread posts. Try again.", actions: [])
                return
        }

        service.loadData(from:
        URL(string: "https://a.4cdn.org/\(board)/thread/\(opNumber).json")!,
                         lastModified: lastModified) { (result) in
            switch result {
            case .success(let response):

                DispatchQueue.main.async {
                    self.reloadButton.isEnabled = true
                }

                switch response.code {
                case 200..<300:
                    self.lastModified = response.modified

                    do {
                        guard let thread = try? JSONDecoder().decode(Thread.self, from: response.data) else {
                            print("error trying to convert data to JSON \(response)")
                            self.showThreadNotFoundAlert(isRefreshing: refreshing)
                            return
                        }

                        self.threadViewModel.posts = thread.posts.map(PostViewModel.init)
                        self.threadViewModel.buildQuotes()

                        DispatchQueue.main.async {
                            self.postsTable.reloadData()
                            self.postsTable.isHidden = false
                            if !refreshing {
                                self.navigateToPost()
                            } else {
                                self.showToast(message: "New posts found.",
                                               textColor: .white,
                                               backgroundColor: .green)
                            }
                        }
                    }
                case 300..<400:
                    self.showToast(message: "No new posts")
                case 400...500:
                    self.showThreadNotFoundAlert(isRefreshing: refreshing)
                default: break
            }

            case .failure(let error):
                self.showAlertView(title: "Fetch failed",
                                   message: "Failed to load thread posts. Try again. \(error.localizedDescription)", actions: [])

                DispatchQueue.main.async {
                    self.loadingIndicator.isHidden = true
                    self.reloadButton.isEnabled = true
                }
            }
        }
    }
   
    private func showThreadNotFoundAlert(isRefreshing: Bool) {
        let action = UIAlertAction(title: "Ok",
                                   style: .default,
                                   handler: { _ in
                                    if !isRefreshing {
                                        self.navigationController?.popViewController(animated: true)
                                    }
        })
        showAlertView(title: "Thread removed",
                           message: "Thread was pruned or deleted. Returning to board list...",
                           actions: [action])
    }
    
    func navigateToPost() {
        guard let postNumberToNavigate = threadViewModel.postNumberToNavigate,
             let index = self.threadViewModel.findPostIndexByNumber(postNumberToNavigate) else { return }
            indexPathNav = IndexPath(item: index, section: 0)
        let indexPaths = self.postsTable.indexPathsForVisibleRows!

        for index in indexPaths {
            let post = threadViewModel.postViewModel(at: index.row)
            if post!.number! == postNumberToNavigate {
                flashThreadLinked()
            }
        }
        self.postsTable.scrollToRow(at: indexPathNav, at: .top, animated: true)
    }
    
    @IBAction func reloadData(_ sender: UIBarButtonItem) {
        DispatchQueue.main.async {
            sender.isEnabled = false
        }
        threadViewModel.reset()
        self.fetchData(refreshing: true)
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
    }
    
    @IBAction func returnToQuoteOriginalPost(_ sender: Any) {
        if !postNumberToReturn.isEmpty {
            let returnNumber = postNumberToReturn.removeLast()
            guard let index = threadViewModel.findPostIndexByNumber(returnNumber) else { return }
            let indexPath = IndexPath(row: index, section: 0)
            postsTable.scrollToRow(at: indexPath, at: .top, animated: true)
        }
    }
    
    @IBAction func gotoTop(_ sender: Any) {
        self.postsTable.scrollToRow(at: IndexPath(item: 0, section: 0),
                                    at: .top, animated: true)
    }
    
    @IBAction func gotoBottom(_ sender: Any) {
        let posts = self.threadViewModel.posts.count
        self.postsTable.scrollToRow(at: IndexPath(item: posts - 1, section: 0),
                                    at: .top, animated: true)
    }
    
    func flashThreadLinked() {
        //print(postsTable.visibleCells)
        guard let index = self.indexPathNav,
        let cell = self.postsTable.cellForRow(at: index)
            else { return }
        UIView.animate(withDuration: 1.0, animations: {
            cell.contentView.backgroundColor = .red
            cell.contentView.backgroundColor = .black
        })
    }
    
    override func viewWillAppear(_ animated: Bool) {
        navigationController?.navigationBar.isHidden = false
    }

    @IBAction func goSettings(_ sender: Any) {
        let settings = SettingsViewController(nibName: "SettingsViewController",
                                              bundle: nil)
        show(settings, sender: self)
    }
}

extension ThreadViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return threadViewModel.posts.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {

        guard let postViewModel: PostViewModel = threadViewModel.postViewModel(at: indexPath.row)
        else { return UITableViewCell() }

        let cell: PostTableViewCell?

        if postViewModel.isHidden {
            cell = tableView.dequeueReusableCell(withIdentifier: "postCell_Hidden_Identifier") as? PostTableViewCell
        } else {
            cell = tableView.dequeueReusableCell(withIdentifier: "postCellIdentifier") as? PostTableViewCell
        }
        
        cell?.setupCell(threadViewModel: threadViewModel, postViewModel: postViewModel,
                        currentBoard: threadViewModel.boardIdToNavigate,
                        tapDelegate: self, toastDelegate: self, hideDelegate: self)

        cell?.setupPostHeader()
        cell?.loadCell()

        return cell ?? UITableViewCell()
    }
}

extension ThreadViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        let footerView = tableView.dequeueReusableHeaderFooterView(
            withIdentifier: "ThreadFooterView") as? ThreadFooterView
        guard let threadToLaunch = threadViewModel.postViewModel(at: 0) else {
            return footerView
        }
        footerView?.threadToNavigate = threadToLaunch.number
        footerView?.imagesCount.text = "\(threadToLaunch.images ?? 0) (\(threadToLaunch.omittedImages ?? 0))"
        footerView?.postsCount.text = "\(threadToLaunch.replies ?? 0) (\(threadToLaunch.omittedPosts ?? 0))"
        footerView?.navigateButton.setTitle("Reply", for: .normal)
        footerView?.navigateButton.isEnabled = !threadToLaunch.isClosed
        footerView?.delegate = !threadToLaunch.isClosed ? self : nil
        footerView?.closedIcon.isHidden = !threadToLaunch.isClosed
        return footerView
    }
    
    func scrollViewDidEndScrollingAnimation(_ scrollView: UIScrollView) {
        flashThreadLinked()
    }

    func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath) -> [UITableViewRowAction]? {

        let reportAction = UITableViewRowAction(style: .normal, title: "Report") { (rowAction, indexPath) in
            //TODO: edit the row at indexPath here
        }
        reportAction.backgroundColor = .red

        let hideAction = UITableViewRowAction(style: .normal, title: "Show/Hide") { (_, indexPath) in
            guard let postViewModel = self.threadViewModel.postViewModel(at: indexPath.row) else { return }
            postViewModel.toggleHidden()
            self.postsTable.reloadData()
        }
        hideAction.backgroundColor = .blue

        return [hideAction]
    }
}

extension ThreadViewController: CellTapInteractionDelegate {
    func linkTapped(postNumber: Int, opNumber: Int, originNumber: Int) {
        self.postNumberToReturn.append(originNumber)
        self.threadViewModel.postNumberToNavigate = postNumber
        self.navigateToPost()
    }

    func imageTapped(_ viewController: UIViewController) {
        show(viewController, sender: self)
    }

    func presentAlertExitingApp(_ actions: [UIAlertAction]) {
        showAlertView(title: "Exit ChanDit",
                      message: "This link will take you outside ChanDit. You are in your own. Proceed?",
                      actions: actions)
    }
}

extension ThreadViewController: ThreadFooterViewDelegate {
    func toggleVisibility(section: Int) {
        //empty
    }

    func threadFooterView(_ footer: ThreadFooterView, threadToNavigate section: Int) {
        let boardToNavigate = threadViewModel.boardIdToNavigate ?? "a"
        let threadNumber = threadViewModel.opNumber ?? 1
        let webVC = SwiftWebVC(
            urlString: "https://boards.4chan.org/\(boardToNavigate)/thread/\(threadNumber)/",
            sharingEnabled: false)
        show(webVC, sender: self)
    }
}

extension ThreadViewController: HideDelegate {
    func hidePost(number: Int) {
        print("hide post \(number)")
    }

    func hideThread(number: Int) {
        print("hide thread \(number)")
        postsTable.isEditing = true
    }
}
