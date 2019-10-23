//
//  WebViewViewController.swift
//  ChanDit
//
//  Created by Vinicius Valvassori on 14/09/19.
//  Copyright © 2019 Vinicius Valvassori. All rights reserved.
//

import UIKit
import WebKit

class WebViewViewController: UIViewController {

    @IBOutlet weak var webView: WKWebView!
    var board: String?
    var thread: Int?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        webView.navigationDelegate = self
        webView.uiDelegate = self
    }
    
    override func viewDidAppear(_ animated: Bool) {
        let url = URL(string: "https://boards.4channel.org/\(board!)/thread/\(thread!)")
        webView.load(URLRequest(url: url!, cachePolicy: .reloadRevalidatingCacheData, timeoutInterval: 10))
    }

}

extension WebViewViewController: WKNavigationDelegate {
    
}

extension WebViewViewController: WKUIDelegate {
    
}

