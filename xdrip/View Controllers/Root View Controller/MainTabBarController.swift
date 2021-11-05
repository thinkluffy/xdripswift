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
        
        removeTabbarItemsText()
    }
    
    func removeTabbarItemsText() {

        var offset: CGFloat = 6.0

        if #available(iOS 11.0, *), traitCollection.horizontalSizeClass == .regular {
            offset = 0.0
        }

        if let items = tabBar.items {
            for item in items {
                item.title = ""
                item.imageInsets = UIEdgeInsets(top: offset, left: 0, bottom: -offset, right: 0)
            }
        }
    }
}
