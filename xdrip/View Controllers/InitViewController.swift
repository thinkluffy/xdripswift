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
            if !UserDefaults.standard.isAgreementAgreed {
                self.showAgreementViewController()
                
            } else {
                self.showMainViewController()
            }
        }
    }
    
    private func showAgreementViewController() {
        let viewController = AgreementViewController()
        viewController.modalPresentationStyle = .overCurrentContext
        present(viewController, animated: false)
    }
    
    private func showMainViewController() {
        UserDefaults.standard.launchCount = UserDefaults.standard.launchCount + 1

        let viewController = R.storyboard.main.mainTabBarController()!
        view.window?.rootViewController = viewController
    }
    
    func agreementDidAgree() {
        UserDefaults.standard.isAgreementAgreed = true
        
        dismiss(animated: false) {
            self.showMainViewController()
        }
    }
}
