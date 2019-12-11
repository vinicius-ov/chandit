//
//  Delegates.swift
//  ChanDit
//
//  Created by Vinicius Valvassori on 18/11/19.
//  Copyright © 2019 Vinicius Valvassori. All rights reserved.
//

protocol CellTapInteractionDelegate: class {
    func linkTapped(postNumber: Int, opNumber: Int, originNumber: Int)
    func imageTapped(_ viewController: UIViewController)
    func presentAlertExitingApp(_ actions: [UIAlertAction])
} 

protocol ToastDelegate: class {
    func showToast(flagHint: String)
}

protocol HideDelegate: class {
    func hidePost(number: Int)
    func hideThread(number: Int)
}
