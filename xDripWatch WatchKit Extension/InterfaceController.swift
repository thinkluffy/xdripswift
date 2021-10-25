//
//  InterfaceController.swift
//  xDripWatch WatchKit Extension
//
//  Created by Yuanbin Cai on 2021/10/25.
//  Copyright © 2021 Johan Degraeve. All rights reserved.
//

import WatchKit
import Foundation
import WatchConnectivity


class InterfaceController: WKInterfaceController {
    
    @IBOutlet var currentBGLabel: WKInterfaceLabel!

    private let session = WCSession.default

    override func awake(withContext context: Any?) {
        // Configure interface objects here.
        print("===> awake")
    }
    
    override func willActivate() {
        print("===> willActivate")

        if WCSession.isSupported() {
            session.delegate = self
            session.activate()
        }
    }
    
    override func didDeactivate() {
        // This method is called when watch view controller is no longer visible
        print("===> didDeactivate")
    }

}

extension InterfaceController: WCSessionDelegate {
    
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        print("===> sessionActivationDidComplete")
        
        currentBGLabel.setText("5.6 ->")
    }
    
    func session(_ session: WCSession, didReceiveUserInfo userInfo: [String : Any] = [:]) {
        print("===> sessionDidReceiveUserInfo, \(userInfo)")
    }
}
