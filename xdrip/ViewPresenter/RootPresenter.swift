//
//  RootPresenter.swift
//  xdrip
//
//  Created by Yuanbin Cai on 2021/11/22.
//  Copyright © 2021 Johan Degraeve. All rights reserved.
//

import UIKit

class RootPresenter: RootP {

    private static let log = Log(type: RootPresenter.self)

    private weak var view: RootV?
    
    init(view: RootV) {
        self.view = view
    }
    
}
