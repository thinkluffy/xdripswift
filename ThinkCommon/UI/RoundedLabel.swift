//
//  RoundedLabel.swift
//  Paintist
//
//  Created by Yuanbin Cai on 2020/5/12.
//  Copyright © 2020 thinkyeah. All rights reserved.
//

import UIKit

public class RoundedLabel: UILabel {

    private let withShadow: Bool
    
    init(bgColor: UIColor = .white, withShadow: Bool = true) {
        self.withShadow = withShadow
        super.init(frame: .zero)
        layer.backgroundColor = bgColor.cgColor
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
    
    public override func layoutSubviews() {
        super.layoutSubviews()
        CALayer.performWithoutAnimation {
            layer.cornerRadius = bounds.size.width / 2
        }
    }
}
