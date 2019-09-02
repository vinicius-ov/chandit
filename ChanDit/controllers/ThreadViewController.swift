//
//  ThreadViewController.swift
//  ChanDit
//
//  Created by Vinicius Valvassori on 23/08/19.
//  Copyright © 2019 Vinicius Valvassori. All rights reserved.
//

import UIKit

class ThreadViewController: UIViewController {

    var threadViewModel = ThreadViewModel()
    var threadNumber: Int!
    @IBOutlet weak var postsTable: UITableView!
    var selectedBoardId: String!
    let service = Service()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        postsTable.isHidden = true
        postsTable.dataSource = self
    }

    fileprivate func fetchData() {
        service.loadData(from: URL(string: "https://a.4cdn.org/\(selectedBoardId!)/thread/\(threadNumber!).json")!) { (result) in
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
                    }
                    //self.threadViewModel.findPostByNumber()
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
    
    @IBAction func reloadData(_ sender: Any) {
        postsTable.isHidden = true
        postsTable.scrollToRow(at: IndexPath(row: 0, section: 0), at: .top, animated: false)
        fetchData()
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
        cell.selectedBoardId = selectedBoardId
        cell.postViewModel = postViewModel
        cell.loadCell()
        cell.parentViewController = self
        
        cell.jumpToPost = { (number: Int?) in
            if let postNumber = number, let index = self.threadViewModel.findPostIndexByNumber(postNumber) {
                let indexPath = IndexPath(item: index, section: 0)
                UIView.animate(withDuration: 0.2, animations: {
                    tableView.scrollToRow(at: indexPath, at: .top, animated: false)
                }, completion: { (done) in
                    UIView.animate(withDuration: 1.0, animations: {
                        print("esta animando")
                        tableView.cellForRow(at: indexPath)?.backgroundColor = .red
                        tableView.cellForRow(at: indexPath)?.backgroundColor = .black
                    })
                }
                )
            }
        }
        return cell
    }
    
    
}
