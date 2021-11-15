//
//  RoundedButton.swift
//  Paintist
//
//  Created by Yuanbin Cai on 2020/4/27.
//  Copyright © 2020 thinkyeah. All rights reserved.
//

import UIKit

class RoundedButton: UIButton {
    
    let withShadow: Bool
    var bgColor: UIColor? {
        get {
            if let color = layer.backgroundColor {
                return UIColor(cgColor: color)
            }
            return nil
        }
        set {
            layer.backgroundColor = newValue?.cgColor
        }
    }
    
    init(bgColor: UIColor? = .white, withShadow: Bool = true) {
        self.withShadow = withShadow
        super.init(frame: .zero)
        layer.backgroundColor = bgColor?.cgColor
        if withShadow {
            layer.shadowColor = UIColor.hex(0xff080a25).cgColor
            layer.shadowOffset = CGSize.zero
            layer.shadowOpacity = 0.2
            layer.shadowRadius = 5
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
 
    override func layoutSubviews() {
        super.layoutSubviews()
        CALayer.performWithoutAnimation {
            layer.cornerRadius = bounds.size.width / 2
        }
    }
}