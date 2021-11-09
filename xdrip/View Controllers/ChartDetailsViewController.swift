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
        navigationController?.popViewController(animated: true)
    }

}
