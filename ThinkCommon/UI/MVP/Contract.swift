//
//  Contract.swift
//  Paintist
//
//  Created by Yuanbin Cai on 2020/4/26.
//  Copyright © 2020 thinkyeah. All rights reserved.
//

import Foundation

protocol MVPV: AnyObject {
    
}

protocol MVPP: AnyObject {
    
    func onViewDidAppear()
    
    func onViewWillDisappear()
    
}

extension MVPP {
    
    func onViewDidAppear() {}
    
    func onViewWillDisappear() {}
}
