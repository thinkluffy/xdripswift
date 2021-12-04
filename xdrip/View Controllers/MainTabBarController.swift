//
//  MainTabBarController.swift
//  xdrip
//
//  Created by Yuanbin Cai on 2021/11/5.
//  Copyright © 2021 Johan Degraeve. All rights reserved.
//

import UIKit

class MainTabBarController: UITabBarController {
        
    override func viewDidLoad() {
        super.viewDidLoad()

        tabBar.tintColor = .white
        // workaround to avoid color change when scroll vertically
        tabBar.barTintColor = ConstantsUI.tabBarBackgroundColor
        
        setupAppearence()
    }
    
    private func setupAppearence() {
        let backgroundColorView = UIView()
        backgroundColorView.backgroundColor = ConstantsUI.tableRowSelectedBackgroundColor
        UITableViewCell.appearance().selectedBackgroundView = backgroundColorView
        UITableViewCell.appearance().backgroundColor = ConstantsUI.contentBackgroundColor
    }
}
