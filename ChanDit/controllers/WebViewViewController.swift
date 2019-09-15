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
    let url: String! = nil
    
    override func viewDidLoad() {
        super.viewDidLoad()
        webView.navigationDelegate = self
        webView.uiDelegate = self
    }
    
    override func viewDidAppear(_ animated: Bool) {
        webView.load(URLRequest(url: URL(string: url)!, cachePolicy: .reloadRevalidatingCacheData, timeoutInterval: 10))
    }

}

extension WebViewViewController: WKNavigationDelegate {
    
}

extension WebViewViewController: WKUIDelegate {
    
}

