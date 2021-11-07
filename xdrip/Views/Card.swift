//
//  Card.swift
//  xdrip
//
//  Created by Yuanbin Cai on 2021/11/7.
//  Copyright © 2021 Johan Degraeve. All rights reserved.
//

import UIKit

@IBDesignable
class Card: UIView {

    @IBInspectable
    var cornerRadius: CGFloat = 10 {
        didSet {
            layer.cornerRadius = cornerRadius
            setNeedsLayout()
        }
    }
    
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
        layer.cornerRadius = cornerRadius
        layer.masksToBounds = true
    }
}
