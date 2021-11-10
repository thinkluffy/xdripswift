//
//  VerticalCenterTextLayer.swift
//  Paintist
//
//  Created by Yuanbin Cai on 2020/3/27.
//  Copyright © 2020 thinkyeah. All rights reserved.
//

import UIKit

public class VerticalCenterTextLayer: CATextLayer {

    override open func draw(in ctx: CGContext) {
        let yDiff: CGFloat
        let fontSize: CGFloat
        let height = self.bounds.height
        if let attributedString = self.string as? NSAttributedString {
            fontSize = attributedString.size().height
            yDiff = (height - fontSize) / 2
            
        } else {
            fontSize = self.fontSize
            yDiff = (height - fontSize) / 2 - fontSize / 10
        }
        ctx.saveGState()
        ctx.translateBy(x: 0.0, y: yDiff)
        super.draw(in: ctx)
        ctx.restoreGState()
    }
}


