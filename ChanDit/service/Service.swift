//
//  Service.swift
//  ChanDit
//
//  Created by Vinicius Valvassori on 02/08/19.
//  Copyright © 2019 Vinicius Valvassori. All rights reserved.
//

import UIKit

class Service: NSObject {
    enum Result {
        case success(Data)
        case failure(Error?)
    }
    
    let session = URLSession(configuration: URLSessionConfiguration.default)
    
    func loadData(from url: URL,
                  completionHandler: @escaping (Result) -> Void) {
        
        let task = session.dataTask(with: url) { data, _, error in
            guard let data = data else {
                completionHandler(.failure(error))
                return
            }
            
            completionHandler(.success(data))
        }
        
        task.resume()
    }
    
}
