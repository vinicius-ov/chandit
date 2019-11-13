//
//  ThreadViewController.swift
//  ChanDit
//
//  Created by Vinicius Valvassori on 23/08/19.
//  Copyright © 2019 Vinicius Valvassori. All rights reserved.
//

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

    override func viewDidLoad() {
        super.viewDidLoad()
        postsTable.isHidden = true
        postsTable.dataSource = self
        postsTable.delegate = self

        postsTable.register(UINib(nibName: "PostCell", bundle: nil), forCellReuseIdentifier: "postCellIdentifier")
        postsTable.register(UINib(nibName: "ThreadFooterView", bundle: nil),
                            forHeaderFooterViewReuseIdentifier: ThreadFooterView.reuseIdentifier)
    
        postsTable.rowHeight = UITableView.automaticDimension
        postsTable.estimatedRowHeight = 400
        
        fetchData()
    }

    fileprivate func fetchData() {
        guard let board = threadViewModel.boardIdToNavigate,
            let opNumber = threadViewModel.threadNumberToNavigate
            else {
                self.showAlertView(title: "Fetch failed",
                message: "Failed to load thread posts. Try again.", actions: [])
                return
        }
        service.loadData(from: URL(string: "https://a.4cdn.org/\(board)/thread/\(opNumber).json")!, lastModified: lastModified) { (result) in
            switch result {
            case .success(let response):
                switch response.code {
                case 200..<300:
                    self.lastModified = response.modified
                    do {
                        guard let thread = try? JSONDecoder().decode(Thread.self, from: response.data) else {
                            print("error trying to convert data to JSON \(response)")
                            self.showThreadNotFoundAlert()
                            return
                        }
                        self.threadViewModel.posts = thread.posts.map(PostViewModel.init)
                        DispatchQueue.main.async {
                            self.title = self.threadViewModel.threadTitle
                            self.postsTable.reloadData()
                            self.postsTable.isHidden = false
                            self.navigateToPost()
                            self.title = self.threadViewModel.postViewModel(at: 0)?.title?.toPlainText().string
                        }
                    }
                case 300..<400:
                    DispatchQueue.main.async {
                        self.showToast(message: "No new posts")
                    }
                case 400...500:
                    self.showThreadNotFoundAlert()
                default: break
                }
                self.reloadButton.isEnabled = true
            case .failure(let error):
                self.showAlertView(title: "Fetch failed",
                                   message: "Failed to load thread posts. Try again. \(error.localizedDescription)", actions: [])
            }
        }
    }
   
    private func showThreadNotFoundAlert() {
        let action = UIAlertAction(title: "Ok",
                                   style: .default,
                                   handler: { _ in
                                    self.navigationController?.popViewController(animated: true)
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
        sender.isEnabled = false
        self.fetchData()
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
        self.postsTable.scrollToRow(at:
            IndexPath(item: 0, section: 0), at: .top, animated: true)
    }
    
    @IBAction func gotoBottom(_ sender: Any) {
        let posts = self.threadViewModel.posts.count
        self.postsTable.scrollToRow(at:
            IndexPath(item: posts - 1, section: 0), at: .top, animated: true)
    }
    
    func flashThreadLinked() {
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
}

extension ThreadViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return threadViewModel.posts.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "postCellIdentifier") as? PostTableViewCell
        let postViewModel = threadViewModel.postViewModel(at: indexPath.row)
        cell?.selectedBoardId = threadViewModel.boardIdToNavigate
        cell?.postViewModel = postViewModel
        cell?.boardName = threadViewModel.completeBoardName!
        cell?.tapDelegate = self
        cell?.flagDelegate = self
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

    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        print("drag")
    }
    
    func scrollViewDidEndScrollingAnimation(_ scrollView: UIScrollView) {
        flashThreadLinked()
    }
}
    
extension UIViewController {
    func showAlertView(title: String, message: String, actions: [UIAlertAction]? = []) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        actions!.forEach {
            alert.addAction($0)
        }
        if actions!.isEmpty {
            let actionOk = UIAlertAction(title: "Ok", style: .default, handler: nil)
            alert.addAction(actionOk)
            
        } else {
            alert.preferredAction = actions!.first!
        }
        DispatchQueue.main.async {
            self.present(alert, animated: true, completion: nil)
        }
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
    func threadFooterView(_ footer: ThreadFooterView, threadToNavigate section: Int) {
        let viewController = WebViewViewController(nibName: "WebViewViewController", bundle: Bundle.main)
        viewController.thread = threadViewModel.opNumber
        viewController.board = threadViewModel.boardIdToNavigate
        show(viewController, sender: nil)
    }
}

