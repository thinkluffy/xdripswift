//
//  ProgressBar.swift
//  Paintist
//
//  Created by Yuanbin Cai on 2020/5/10.
//  Copyright © 2020 thinkyeah. All rights reserved.
//

import UIKit

public class ProgressBar: UIView {
    
    public var roundedCornors: Bool = false {
        didSet {
            if roundedCornors {
                layer.cornerRadius = bounds.height / 2
                progressLayer.cornerRadius = bounds.height / 2
                
            } else {
                layer.cornerRadius = 0
                progressLayer.cornerRadius = 0
            }
        }
    }
    
    public var barColor: UIColor = .white {
        didSet {
            progressLayer.backgroundColor = barColor.cgColor
        }
    }
    
    private let progressLayer = CALayer()
    private var progress: Float = 0
    
    init() {
        super.init(frame: .zero)
        backgroundColor = UIColor.black
        layer.addSublayer(progressLayer)
        
        progressLayer.backgroundColor = barColor.cgColor
        progressLayer.frame = .zero
        
        clipsToBounds = true
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public override func layoutSubviews() {
        super.layoutSubviews()
        CALayer.performWithoutAnimation {
            progressLayer.frame = CGRect(x: 0, y: 0,
                                         width: bounds.width * CGFloat(progress),
                                         height: bounds.height)
            
            if roundedCornors {
                layer.cornerRadius = bounds.height / 2
                progressLayer.cornerRadius = bounds.height / 2
            }
        }
    }
    
    public func setProgress(_ progress: Float, animated: Bool = true) {
        if !animated {
            CALayer.performWithoutAnimation {
                progressLayer.frame.size = CGSize(width: bounds.width * CGFloat(progress), height: bounds.height)
            }
            
        } else {
            progressLayer.frame.size = CGSize(width: bounds.width * CGFloat(progress), height: bounds.height)
        }
        self.progress = progress
    }
}
