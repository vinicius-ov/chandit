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
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        postsTable.dataSource = self
        
        let service = Service()
        service.loadData(from: URL(string: "https://a.4cdn.org/v/thread/\(threadNumber ?? 1 ).json")!) { (result) in
            switch result {
            case .success(let data):
                do {
                    guard let thread = try? JSONDecoder().decode(Thread.self, from: data) else {
                        print("error trying to convert data to JSON \(data)")
                        return
                    }
                    
                    self.threadViewModel.posts = thread.posts.map(PostViewModel.init)
                    
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
    
}

extension ThreadViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return threadViewModel.posts.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "postCell") as! PostTableViewCell
        //let thread = pageViewModel.threads[indexPath.section]
        let post = threadViewModel.postViewModel(at: indexPath.row)
        cell.postViewModel = post
        cell.loadCell()
        return cell
    }
    
    
}
