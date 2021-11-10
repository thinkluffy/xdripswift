//
//  MVPViewController.swift
//  Paintist
//
//  Created by Yuanbin Cai on 2020/4/26.
//  Copyright © 2020 thinkyeah. All rights reserved.
//

import UIKit

class MVPViewController<P: MVPP>: UIViewController, MVPV {
    
    var presenter: P!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        if presenter == nil {
            presenter = presenterInstance()
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        presenter.onViewDidAppear()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        presenter.onViewWillDisappear()
        super.viewWillDisappear(animated)
    }
    
    func presenterInstance() -> P {
        fatalError("Override to instance presenter and save")
    }
}
