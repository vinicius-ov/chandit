//
//  ViewController.swift
//  ChanDit
//
//  Created by Vinicius Valvassori on 02/08/19.
//  Copyright © 2019 Vinicius Valvassori. All rights reserved.
//

import UIKit

class ViewController: UIViewController {
    
    @IBOutlet weak var postsTable: UITableView!
    var pageViewModel = PageViewModel()
    //var threadsViewModel = ThreadViewModel()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        postsTable.dataSource = self
        postsTable.rowHeight = UITableView.automaticDimension
        postsTable.estimatedRowHeight = 400
    }
    
    override func motionEnded(_ motion: UIEvent.EventSubtype, with event: UIEvent?){
        if motion == .motionShake
        {
            postsTable.reloadData()
        }
    }
    
    override func viewDidLayoutSubviews() {
//        print(postImage.frame.width)
//        print(self.view.bounds.width)
        let service = Service()
        service.loadData(from: URL(string: "https://a.4cdn.org/v/1.json")!) { (result) in
            switch result {
            case .success(let data):
                do {
                    guard let page = try? JSONDecoder().decode(Page.self, from: data) else {
                            print("error trying to convert data to JSON \(data)")
                            return
                    }
                    // now we have the todo
                    // let's just print it to prove we can access it
                    //print("The todo is: \(page.threads.first)")
                    //self.threads = page.threads
                    //page.threads.map(PostViewModel.init)
//                    pageViewModel.threads = page.threads.map({
//                        return $0.posts.map(PostViewModel.init)
//                    })
                    self.pageViewModel.threads = page.threads.map ({ (thread: Thread) in
                        let tvm = ThreadViewModel.init(thread: thread)
                        return tvm
                    })
                    
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

extension ViewController : UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return pageViewModel.threads[section].posts.count
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return pageViewModel.threads.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "postCell") as! PostTableViewCell
        let thread = pageViewModel.threads[indexPath.section]
        let post = thread.postViewModel(at: indexPath.row)
        cell.postViewModel = post
        cell.loadCell()
        return cell
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return "TITLE"
    }
}


