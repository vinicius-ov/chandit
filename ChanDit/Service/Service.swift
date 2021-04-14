//
//  Service.swift
//  ChanDit
//
//  Created by Vinicius Valvassori on 02/08/19.
//  Copyright © 2019 Vinicius Valvassori. All rights reserved.
//

import UIKit

class Service: NSObject {
    
    struct ChanditSuccess {
        var data: Data
        var modified: String
        var code: Int
    }

    enum Result {
        case success(ChanditSuccess)
        case failure(Error)
    }

    var session: URLSession!

    init(delegate: URLSessionDelegate) {
        super.init()
        session = URLSession(configuration: URLSessionConfiguration.default,
                             delegate: delegate, delegateQueue: nil)
    }

    override init() {
        super.init()
        session = URLSession(configuration: URLSessionConfiguration.default)
    }

    func loadData(from url: URL, lastModified: String?,
                  completionHandler: @escaping (Result) -> Void) {
        var request = URLRequest(url: url)
        if let modified = lastModified {
            request.addValue(modified, forHTTPHeaderField: "If-Modified-Since")
            request.cachePolicy = .reloadIgnoringCacheData
        }

        let task = session.dataTask(with: request) { data, response, error in
            guard let data = data,
                let response = response as? HTTPURLResponse
                else {
                    completionHandler(.failure(error!))
                return
            }
            let chandit = ChanditSuccess(
                data: data,
                modified: response.allHeaderFields["Last-Modified"] as? String ?? "",
                code: response.statusCode)
            completionHandler(.success(chandit))
        }

        task.resume()
    }

    func loadVideoData(from url: URL) -> URLSessionTask {
        return session.downloadTask(with: url)
    }
}
