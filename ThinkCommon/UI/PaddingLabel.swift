//
//  PaddingLabel.swift
//  Paintist
//
//  Created by Yuanbin Cai on 2020/8/6.
//  Copyright © 2020 thinkyeah. All rights reserved.
//

import UIKit

public class PaddingLabel: UILabel {
    
    private var edgeInsets: UIEdgeInsets
    
    required init(edgeInsets: UIEdgeInsets) {
        self.edgeInsets = edgeInsets
        super.init(frame: .zero)
    }
    
    convenience init(top: CGFloat, left: CGFloat, bottom: CGFloat, right: CGFloat) {
        self.init(edgeInsets: UIEdgeInsets(top: top, left: left, bottom: bottom, right: right))
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public override func drawText(in rect: CGRect) {
        super.drawText(in: rect.inset(by: edgeInsets))
    }
    
    public override var intrinsicContentSize: CGSize {
        var contentSize = super.intrinsicContentSize
        contentSize.height += edgeInsets.top + edgeInsets.bottom
        contentSize.width += edgeInsets.left + edgeInsets.right
        return contentSize
    }
}
