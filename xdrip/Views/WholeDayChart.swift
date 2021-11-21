//
//  WholeDayChart.swift
//  xdrip
//
//  Created by Yuanbin Cai on 2021/11/21.
//  Copyright © 2021 Johan Degraeve. All rights reserved.
//

import UIKit

class WholeDayChart: UIView {

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        initialize()
    }
    
    init() {
        super.init(frame: .zero)
        initialize()
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        initialize()
    }
    
    private func initialize() {
    }
}
