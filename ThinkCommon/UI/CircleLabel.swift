//
//  CircleLabel.swift
//  Paintist
//
//  Created by Yuanbin Cai on 2020/6/17.
//  Copyright © 2020 thinkyeah. All rights reserved.
//

import UIKit

class CircleLabel: UILabel {
        
    var bgColor: UIColor = .red {
        didSet {
            layer.backgroundColor = bgColor.cgColor
        }
    }
    
    init() {
        super.init(frame: .zero)
        setup()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setup() {
        layer.backgroundColor = bgColor.cgColor
        textAlignment = .center
        textColor = .white
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        layer.cornerRadius = min(bounds.width, bounds.height) / 2
    }
}
