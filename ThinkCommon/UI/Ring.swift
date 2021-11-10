//
//  Ring.swift
//  Paintist
//
//  Created by Yuanbin Cai on 2020/5/15.
//  Copyright © 2020 thinkyeah. All rights reserved.
//

import UIKit

class Ring: UIView {

    private let ringBgLayer = CAShapeLayer()
    private let ringLayer = CAShapeLayer()

    var progress: Float = 0 {
        didSet {
            ringLayer.strokeEnd = CGFloat(progress)
        }
    }
    
    init(bgColor: UIColor = .clear, ringColor: UIColor = .red, lineWidth: CGFloat = 2) {
        super.init(frame: .zero)

        ringBgLayer.frame = bounds
        ringBgLayer.strokeColor = bgColor.cgColor
        ringBgLayer.lineWidth = lineWidth
        ringBgLayer.fillColor = UIColor.clear.cgColor
        
        layer.addSublayer(ringBgLayer)
        
        ringLayer.frame = bounds
        ringLayer.strokeColor = ringColor.cgColor
        ringLayer.lineWidth = lineWidth
        ringLayer.fillColor = UIColor.clear.cgColor
        ringLayer.lineCap = .round
        ringLayer.strokeEnd = 0
        
        layer.addSublayer(ringLayer)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        ringBgLayer.frame = bounds
        ringBgLayer.path = UIBezierPath(arcCenter: center,
                                      radius: ringBgLayer.bounds.height / 2 + 4,
                                      startAngle: -CGFloat.pi * 0.5,
                                      endAngle: CGFloat.pi * 1.5,
                                      clockwise: true).cgPath
        
        ringLayer.frame = bounds
        ringLayer.path = UIBezierPath(arcCenter: center,
                                      radius: ringLayer.bounds.height / 2 + 4,
                                      startAngle: -CGFloat.pi * 0.5,
                                      endAngle: CGFloat.pi * 1.5,
                                      clockwise: true).cgPath
    }
    
    func playProgressAnimation(duration: CFTimeInterval, from: CGFloat = 0, to: CGFloat = 1) {
        let animation = CABasicAnimation(keyPath: "strokeEnd")
        animation.duration = duration
        animation.fromValue = 1.0
        animation.toValue = 0.0
        animation.fillMode = .forwards
        animation.isRemovedOnCompletion = false
        ringLayer.add(animation, forKey: animation.keyPath)
    }
    
    func stopProgressAnimation() {
        ringLayer.removeAllAnimations()
    }
}

