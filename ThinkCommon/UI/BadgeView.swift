//
//  BadgeView.swift
//  Paintist
//
//  Created by chengyu sun on 2020/7/1.
//  Copyright © 2020 thinkyeah. All rights reserved.
//

import UIKit

public class BadgeView: UIView {

    private let badgeTextLayer = VerticalCenterTextLayer()
    
    public var string: String = "" {
        didSet {
            badgeTextLayer.string = string
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
        badgeTextLayer.frame = CGRect(x: 0, y: 0, width: 20, height: 20)
        badgeTextLayer.foregroundColor = UIColor.white.cgColor
        badgeTextLayer.fontSize = 11
        badgeTextLayer.alignmentMode = .center
        badgeTextLayer.contentsScale = UIScreen.main.scale
        
        layer.cornerRadius = 10
        clipsToBounds = true
        layer.backgroundColor = UIColor.rgba(255, 36, 78).cgColor
        layer.addSublayer(badgeTextLayer)
        backgroundColor = .red
    }
}
