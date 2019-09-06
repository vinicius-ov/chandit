//
//  ThreadViewController.swift
//  ChanDit
//
//  Created by Vinicius Valvassori on 23/08/19.
//  Copyright © 2019 Vinicius Valvassori. All rights reserved.
//

import UIKit

class ThreadViewController: UIViewController {

    var threadViewModel: ThreadViewModel!
    var threadNumber: Int!
    //var postNumberToNavigate: Int!
    var postNumberToReturn = [Int]()
    @IBOutlet weak var postsTable: UITableView!
    var selectedBoardId: String!
    let service = Service()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        postsTable.isHidden = true
        postsTable.dataSource = self
        postsTable.prefetchDataSource = self
        postsTable.rowHeight = UITableView.automaticDimension
        postsTable.estimatedRowHeight = 460
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
                        self.navigateToPost(inTableView: self.postsTable, forIndexPath: nil)
                    }
                }
                break
            case .failure(let error):
                break
            }
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        fetchData()
    }
    
    func navigateToPost(inTableView tableView: UITableView, forIndexPath indexPath: IndexPath?) {
        guard let postNumberToNavigate = threadViewModel.postNumberToNavigate,
             let index = self.threadViewModel.findPostIndexByNumber(postNumberToNavigate) else { return }
            let indexPathNav = indexPath ?? IndexPath(item: index, section: 0)
            UIView.animate(withDuration: 0.2, animations: {
                tableView.scrollToRow(at: indexPathNav, at: .top, animated: false)
            }, completion: { (done) in
                UIView.animate(withDuration: 1.0, animations: {
                    tableView.cellForRow(at: indexPathNav)?.backgroundColor = .red
                    tableView.cellForRow(at: indexPathNav)?.backgroundColor = .black
                })
            })
    }
    
    @IBAction func reloadData(_ sender: Any) {
        postsTable.isHidden = true
        //postsTable.scrollToRow(at: IndexPath(row: 0, section: 0), at: .top, animated: false)
        fetchData()
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        //postNumberToNavigate = nil
    }
    
    @IBAction func returnToQuoteOriginalPost(_ sender: Any) {
        if !postNumberToReturn.isEmpty {
            let returnNumber = postNumberToReturn.removeLast()
            guard let index = threadViewModel.findPostIndexByNumber(returnNumber) else { return }
            let indexPath = IndexPath(row: index, section: 0)
            postsTable.scrollToRow(at: indexPath, at: .top, animated: true)
        }
    }
    
}

extension ThreadViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return threadViewModel.posts.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "postCell") as! PostTableViewCell
        //let thread = pageViewModel.threads[indexPath.section]
        let postViewModel = threadViewModel.postViewModel(at: indexPath.row)
        cell.selectedBoardId = threadViewModel.boardIdToNavigate
        cell.postViewModel = postViewModel
        cell.loadCell()
        cell.parentViewController = self
        
        cell.jumpToPost = { (number: Int?) in
            if let postNumber = number, let index =
                self.threadViewModel.findPostIndexByNumber(postNumber) {
                //self.postNumberToNavigate = postNumber
                self.postNumberToReturn.append(postViewModel.number!)
                let indexPathNav = IndexPath(item: index, section: 0)
                self.navigateToPost(inTableView: tableView, forIndexPath: indexPathNav)
            }
        }
        return cell
    }
    
}

extension ThreadViewController: UITableViewDataSourcePrefetching {
    func tableView(_ tableView: UITableView, prefetchRowsAt indexPaths: [IndexPath]) {
//        print("\(indexPaths)")
//        if indexPaths.contains([0,threadViewModel.posts.count-1]) {
//            print("RELOAD!!!!")
//            fetchData()
//        }
    }
    
}
