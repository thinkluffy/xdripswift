//
//  VerticalButton.swift
//  Paintist
//
//  Created by Yuanbin Cai on 2020/4/24.
//  Copyright © 2020 thinkyeah. All rights reserved.
//

import UIKit

/// Image and Title, vertically
class VerticalButton: UIControl {
    
    let imageView = UIImageView()
    let titleLabel = UILabel()
        
    private let gapBetweenImageAndButton: CGFloat
    
    init(gapBetweenImageAndButton: CGFloat = 0) {
        self.gapBetweenImageAndButton = gapBetweenImageAndButton
        super.init(frame: .zero)
        setup()
    }
    
    required init?(coder: NSCoder) {
        self.gapBetweenImageAndButton = 0
        super.init(coder: coder)
        setup()
    }
    
    private func setup() {
        imageView.contentMode = .scaleAspectFit
        
        addSubview(imageView)
        addSubview(titleLabel)
        
        imageView.snp.makeConstraints { (make) in
            make.centerX.equalTo(self)
        }
        
        titleLabel.snp.makeConstraints { (make) in
            make.centerX.equalTo(self)
            make.top.equalTo(imageView.snp.bottom).offset(gapBetweenImageAndButton)
        }
        snp.makeConstraints { (make) in
            make.top.equalTo(imageView)
            make.bottom.equalTo(titleLabel)
            make.leading.lessThanOrEqualTo(imageView)
            make.leading.lessThanOrEqualTo(titleLabel)
            make.trailing.greaterThanOrEqualTo(imageView)
            make.trailing.greaterThanOrEqualTo(titleLabel)
        }
    }
}
