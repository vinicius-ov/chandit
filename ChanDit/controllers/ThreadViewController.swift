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
    @IBOutlet weak var postsTable: UITableView!
    var selectedBoardId: String!
    let service = Service()

    override func viewDidLoad() {
        super.viewDidLoad()
        postsTable.isHidden = true
        postsTable.dataSource = self
        postsTable.delegate = self

        postsTable.register(UINib(nibName: "PostCell", bundle: nil), forCellReuseIdentifier: "postCellIdentifier")
        postsTable.register(UINib(nibName: "ThreadFooterView", bundle: nil), forHeaderFooterViewReuseIdentifier: ThreadFooterView.reuseIdentifier)
    
        postsTable.rowHeight = UITableView.automaticDimension
        postsTable.estimatedRowHeight = 260
        fetchData()
    }

    fileprivate func fetchData() {
        service.loadData(from: URL(string: "https://a.4cdn.org/\(threadViewModel.boardIdToNavigate!)/thread/\(threadViewModel.threadNumberToNavigate!).json")!) { (result) in
            switch result {
            case .success(let data):
                do {
                    guard let thread = try? JSONDecoder().decode(Thread.self, from: data) else {
                        print("error trying to convert data to JSON \(data)")
                        return
                    }
                   
                    self.threadViewModel.posts = thread.posts.map(PostViewModel.init)
                   
                    DispatchQueue.main.async {
                        self.title = self.threadViewModel.threadTitle
                        self.postsTable.reloadData()
                        self.postsTable.isHidden = false
                        self.navigateToPost()
                    }
                }
                break
            case .failure(_):
                break
            }
        }
    }
   
    func navigateToPost() {
        guard let postNumberToNavigate = threadViewModel.postNumberToNavigate,
             let index = self.threadViewModel.findPostIndexByNumber(postNumberToNavigate) else { return }
            let indexPathNav = IndexPath(item: index, section: 0)
            UIView.animate(withDuration: 0.2, animations: {
                self.postsTable.scrollToRow(at: indexPathNav, at: .top, animated: false)
            }, completion: { (done) in
                UIView.animate(withDuration: 1.0, animations: {
                    self.postsTable.cellForRow(at: indexPathNav)?.backgroundColor = .red
                    self.postsTable.cellForRow(at: indexPathNav)?.backgroundColor = .black
                })
            })
    }
    
    @IBAction func reloadData(_ sender: Any) {
        self.postsTable.isHidden = true
        self.threadViewModel.reset()
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
//        var time = 0.5
        let posts = self.threadViewModel.posts.count
//        switch posts {
//        case 50..<100:
//            time = 1.0
//        case (100...):
//            time = 2.0
//        default:
//            time = 0.5
//        }
        //UIView.animate(withDuration: time, animations: { [weak self] in
            self.postsTable.scrollToRow(at:
                IndexPath(item: posts - 1, section: 0), at: .top, animated: true)
        //})
    }
}

extension ThreadViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return threadViewModel.posts.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "postCellIdentifier") as? PostTableViewCell
        //let thread = pageViewModel.threads[indexPath.section]
        let postViewModel = threadViewModel.postViewModel(at: indexPath.row)
        cell?.selectedBoardId = threadViewModel.boardIdToNavigate
        cell?.postViewModel = postViewModel
        cell?.boardName = threadViewModel.completeBoardName!
        cell?.loadCell()
        cell?.tapDelegate = self
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
}

extension UIViewController {
    func callAlertView(title: String, message: String, actions: [UIAlertAction]) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        actions.forEach {
            alert.addAction($0)
        }
        if actions.isEmpty {
            let actionOk = UIAlertAction(title: "Ok", style: .default, handler: nil)
            alert.addAction(actionOk)
            
        } else {
            alert.preferredAction = actions.first!
        }
        present(alert, animated: true, completion: nil)
    }
}

extension ThreadViewController: CellTapInteractionDelegate {
    func linkTapped(postNumber: Int, opNumber: Int) {
        self.postNumberToReturn.append(postNumber)
        self.threadViewModel.postNumberToNavigate = postNumber
        self.navigateToPost()
    }

    func imageTapped(_ viewController: UIViewController) {
        show(viewController, sender: self)
    }

    func presentAlertExitingApp(_ actions: [UIAlertAction]) {
        callAlertView(title: "Exit ChanDit",
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
