//
//  GlucoseIndicator.swift
//  xdrip
//
//  Created by Yuanbin Cai on 2021/11/7.
//  Copyright © 2021 Johan Degraeve. All rights reserved.
//

import UIKit
import SnapKit

class GlucoseIndicator: UIView {

    var reading: (valueInMgDl: Double, showAsMgDl: Bool)? {
        didSet {
            if let reading = reading {
                valueLabel.text = BgReading.unitizedString(calculatedValue: reading.valueInMgDl,
                                                           unitIsMgDl: reading.showAsMgDl)
                unitLabel.text = reading.showAsMgDl ? "mg/dL" : "mmol/L"
                
                if reading.valueInMgDl >= UserDefaults.standard.urgentHighMarkValue ||
                    reading.valueInMgDl <= UserDefaults.standard.urgentLowMarkValue {
                    // BG is higher than urgentHigh or lower than urgentLow objectives
                    innerCircleBgLayer.fillColor = ConstantsGlucoseChart.glucoseUrgentRangeColor.cgColor
                    
                } else if reading.valueInMgDl >= UserDefaults.standard.highMarkValue ||
                        reading.valueInMgDl <= UserDefaults.standard.lowMarkValue  {
                    // BG is between urgentHigh/high and low/urgentLow objectives
                    innerCircleBgLayer.fillColor = ConstantsGlucoseChart.glucoseNotUrgentRangeColor.cgColor

                } else {
                    // BG is between high and low objectives so considered "in range"
                    innerCircleBgLayer.fillColor = ConstantsGlucoseChart.glucoseInRangeColor.cgColor
                }
                
            } else {
                valueLabel.text = "---"
                unitLabel.text = "---"
                innerCircleBgLayer.fillColor = GlucoseIndicator.InnerCircleBgNoValueColor.cgColor
            }
        }
    }
    
    private static let InnerCircleBgNoValueColor = UIColor.lightGray
    
    private let innerCircleBgLayer = CAShapeLayer()
    private let outerRingLayer = CAShapeLayer()

    private let valueLabel: UILabel = {
        let label = UILabel()
        label.textColor = ConstantsUI.contentBackgroundColor
        label.font = .systemFont(ofSize: 45)
        label.text = "---"
        return label
    }()
    
    private let unitLabel: UILabel = {
        let label = UILabel()
        label.textColor = ConstantsUI.contentBackgroundColor
        label.font = .systemFont(ofSize: 16)
        label.text = "---"
        return label
    }()
    
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
        let boundsCenter = CGPoint(x: bounds.midX, y: bounds.midY)
        
        let circlePathArea = CGRect(center: boundsCenter, radius: 60)
        innerCircleBgLayer.path = UIBezierPath(ovalIn: circlePathArea).cgPath
        innerCircleBgLayer.fillColor = GlucoseIndicator.InnerCircleBgNoValueColor.cgColor
        layer.addSublayer(innerCircleBgLayer)

        outerRingLayer.path = UIBezierPath(arcCenter: boundsCenter,
                                           radius: 68,
                                           startAngle: -CGFloat.pi * 0.5,
                                           endAngle: CGFloat.pi * 1.5,
                                           clockwise: true).cgPath
        outerRingLayer.strokeColor = ConstantsUI.contentBackgroundColor.cgColor
        outerRingLayer.lineWidth = 10
        outerRingLayer.fillColor = UIColor.clear.cgColor
        layer.addSublayer(outerRingLayer)
        
        addSubview(valueLabel)
        addSubview(unitLabel)
        
        valueLabel.snp.makeConstraints { (make) in
            make.centerX.equalTo(self.snp.centerX)
            make.centerY.equalTo(self.snp.centerY).offset(-10)
        }
        
        unitLabel.snp.makeConstraints { (make) in
            make.centerX.equalTo(self.snp.centerX)
            make.centerY.equalTo(self.snp.centerY).offset(25)
        }
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        let boundsCenter = CGPoint(x: bounds.midX, y: bounds.midY)
        
        let circlePathArea = CGRect(center: boundsCenter, radius: 60)
        innerCircleBgLayer.path = UIBezierPath(ovalIn: circlePathArea).cgPath
        
        outerRingLayer.path = UIBezierPath(arcCenter: boundsCenter,
                                           radius: 68,
                                           startAngle: -CGFloat.pi * 0.5,
                                           endAngle: CGFloat.pi * 1.5,
                                           clockwise: true).cgPath
    }
}
