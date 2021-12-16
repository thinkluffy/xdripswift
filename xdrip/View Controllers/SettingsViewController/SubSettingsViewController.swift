//
//  SubSettingsViewController.swift
//  xdrip
//
//  Created by Yuanbin Cai on 2021/12/11.
//  Copyright © 2021 Johan Degraeve. All rights reserved.
//

import UIKit

class SubSettingsViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

        navigationItem.largeTitleDisplayMode = .never
    }
    
    override var hidesBottomBarWhenPushed: Bool {
        get {
            return true
        }
        set {
            super.hidesBottomBarWhenPushed = newValue
        }
    }
}
