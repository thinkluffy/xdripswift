//
//  SensorIndicator.swift
//  xdrip
//
//  Created by Yuanbin Cai on 2021/12/3.
//  Copyright © 2021 Johan Degraeve. All rights reserved.
//

import UIKit

@IBDesignable
class SensorIndicator: UIControl {
    
    private let outerCircleBgLayer = CAShapeLayer()
    private let innerCircleBgLayer = CAShapeLayer()
    
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
        backgroundColor = .clear
        
        let boundsCenter = CGPoint(x: bounds.midX, y: bounds.midY)
        
        let outerCircleRadius: CGFloat = min(bounds.width, bounds.height) / 2
        
        var circlePathArea = CGRect(origin: .zero, size: CGSize(width: outerCircleRadius * 2, height: outerCircleRadius * 2))
        outerCircleBgLayer.path = UIBezierPath(ovalIn: circlePathArea).cgPath
        outerCircleBgLayer.fillColor = UIColor.white.cgColor
        outerCircleBgLayer.frame = CGRect(center: boundsCenter, radius: outerCircleRadius)
        layer.addSublayer(outerCircleBgLayer)
        
        let innerCircleRadius: CGFloat = 2
        circlePathArea = CGRect(origin: .zero, size: CGSize(width: innerCircleRadius * 2, height: innerCircleRadius * 2))
        innerCircleBgLayer.path = UIBezierPath(ovalIn: circlePathArea).cgPath
        innerCircleBgLayer.fillColor = ConstantsUI.mainBackgroundColor.cgColor
        innerCircleBgLayer.frame = CGRect(center: boundsCenter, radius: innerCircleRadius)
        layer.addSublayer(innerCircleBgLayer)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        let boundsCenter = CGPoint(x: bounds.midX, y: bounds.midY)
        
        outerCircleBgLayer.frame.origin = CGPoint(x: boundsCenter.x - outerCircleBgLayer.bounds.size.width / 2,
                                                  y: boundsCenter.y - outerCircleBgLayer.bounds.size.height / 2)
        innerCircleBgLayer.frame.origin = CGPoint(x: boundsCenter.x - innerCircleBgLayer.bounds.size.width / 2,
                                                  y: boundsCenter.y - innerCircleBgLayer.bounds.size.height / 2)
    }
    
    override func prepareForInterfaceBuilder() {
        invalidateIntrinsicContentSize()
    }
}
