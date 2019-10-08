//
//  BaseNavigationController.swift
//  ChanDit
//
//  Created by Bemacash on 07/10/19.
//  Copyright © 2019 Vinicius Valvassori. All rights reserved.
//

import UIKit

class BaseNavigationController: UINavigationController {

    override var shouldAutorotate: Bool {
        return topViewController?.shouldAutorotate ?? super.shouldAutorotate
    }
    
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return topViewController?.supportedInterfaceOrientations ?? super.supportedInterfaceOrientations
    }

}
