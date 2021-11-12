//
//  ChartDetailsViewController.swift
//  xdrip
//
//  Created by Yuanbin Cai on 2021/11/9.
//  Copyright © 2021 Johan Degraeve. All rights reserved.
//

import UIKit

class ChartDetailsViewController: UIViewController {

    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    @IBAction func exitButtonClicked(_ sender: UIButton) {
        dismiss(animated: false)
    }

    // make the ViewController landscape mode
    override public var shouldAutorotate: Bool {
        return false
    }
    
    override public var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return .landscapeLeft
    }
    
    override public var preferredInterfaceOrientationForPresentation: UIInterfaceOrientation {
        return .landscapeLeft
    }
}
