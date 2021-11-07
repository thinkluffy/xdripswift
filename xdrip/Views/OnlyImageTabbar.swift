//
//  OnlyImageTabbar.swift
//  xdrip
//
//  Created by Yuanbin Cai on 2021/11/7.
//  Copyright © 2021 Johan Degraeve. All rights reserved.
//

import UIKit

class OnlyImageTabbar: UITabBar {

    override func layoutSubviews() {
        super.layoutSubviews()

        // remove text titles
        subviews.forEach { subview in
            if subview is UIControl {
                subview.subviews.forEach {
                    if $0 is UILabel {
                        $0.isHidden = true
                        subview.frame.origin.y = $0.frame.height / 2.0
                    }
                }
            }
        }
    }
}
