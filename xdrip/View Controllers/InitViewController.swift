//
//  InitViewController.swift
//  xdrip
//
//  Created by Yuanbin Cai on 2021/11/24.
//  Copyright © 2021 Johan Degraeve. All rights reserved.
//

import UIKit

class InitViewController: UIViewController {
   
    private static let log = Log(type: InitViewController.self)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        CoreDataManager.shared.initialize(modelName: ConstantsCoreData.modelName) {
            self.showMainViewController()
        }
    }

    private func showMainViewController() {
        let mainViewController = R.storyboard.main.mainTabBarController()!
        view.window?.rootViewController = mainViewController
    }
}
