//
//  NotifyLayoutView.swift
//  Paintist
//
//  Created by Yuanbin Cai on 2020/8/13.
//  Copyright © 2020 thinkyeah. All rights reserved.
//

import UIKit

public protocol NotifyLayoutViewDelegate: AnyObject {
    
    func notifyLayoutViewLayoutDidChange(_ view: NotifyLayoutView)
}

public class NotifyLayoutView: UIView {
    
    public weak var delegate: NotifyLayoutViewDelegate?
    
    public override func layoutSubviews() {
        super.layoutSubviews()
        delegate?.notifyLayoutViewLayoutDidChange(self)
    }
}
