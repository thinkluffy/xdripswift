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
    
    private static let log = Log(type: GlucoseIndicator.self)

    var reading: (valueInMgDl: Double, showAsMgDl: Bool, slopeArrow: BgReading.SlopeArrow?)? {
        didSet {
            if let reading = reading {
                GlucoseIndicator.log.d("show new reading, valueInMg: \(reading.valueInMgDl), asMg: \(reading.showAsMgDl), slope: \(reading.slopeArrow?.description ?? "nil")")

                if !BgReading.isNormalValue(reading.valueInMgDl) {
                    valueLabelMgDl.text = BgReading.unitizedString(calculatedValue: reading.valueInMgDl,
                                                                   unitIsMgDl: reading.showAsMgDl)
                    valueLabelMgDl.isHidden = false
                    valueLabelInMmol.isHidden = true
                    
                } else {
                    if reading.showAsMgDl {
                        valueLabelMgDl.text = BgReading.unitizedString(calculatedValue: reading.valueInMgDl,
                                                                       unitIsMgDl: true)
                        valueLabelMgDl.isHidden = false
                        valueLabelInMmol.isHidden = true

                    } else {
                        let valueInMmol = reading.valueInMgDl.mgdlToMmol()
                        valueLabelInMmol.bgValueInMmol = valueInMmol
                        
                        valueLabelMgDl.isHidden = true
                        valueLabelInMmol.isHidden = false
                    }
                }
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
                
                if let slopeArrow = reading.slopeArrow {
                    slopPointerLayer.isHidden = false
                    slopPointerInnerLayer.backgroundColor = innerCircleBgLayer.fillColor
                    switch slopeArrow {
                    case .doubleDown, .singleDown:
                        slopPointerLayer.transform = CATransform3DMakeRotation(45 / 180.0 * .pi, 0, 0, 1)
                    case .fortyFiveDown:
                        slopPointerLayer.transform = CATransform3DMakeRotation(0 / 180.0 * .pi, 0, 0, 1)
                    case .flat:
                        slopPointerLayer.transform = CATransform3DMakeRotation(-45 / 180.0 * .pi, 0, 0, 1)
                    case .fortyFiveUp:
                        slopPointerLayer.transform = CATransform3DMakeRotation(-90 / 180.0 * .pi, 0, 0, 1)
                    case .singleUp, .doubleUp:
                        slopPointerLayer.transform = CATransform3DMakeRotation(-135 / 180.0 * .pi, 0, 0, 1)
                    }
                    
                } else {
                    slopPointerLayer.isHidden = true
                }
                
            } else {
                valueLabelMgDl.text = "---"
                valueLabelMgDl.isHidden = false
                valueLabelInMmol.isHidden = true
                unitLabel.text = "---"
                innerCircleBgLayer.fillColor = GlucoseIndicator.InnerCircleBgNoValueColor.cgColor
                slopPointerInnerLayer.backgroundColor = innerCircleBgLayer.fillColor
                slopPointerLayer.isHidden = true
            }
        }
    }
    
    private static let InnerCircleBgNoValueColor = UIColor.lightGray
    
    private let slopPointerLayer = CAShapeLayer()
    private let slopPointerInnerLayer = CAShapeLayer()
    private let outerCircleBgLayer = CAShapeLayer()
    private let innerCircleBgLayer = CAShapeLayer()

    private let valueLabelMgDl: UILabel = {
        let label = UILabel()
        label.textColor = ConstantsUI.contentBackgroundColor
        label.font = .monospacedDigitSystemFont(ofSize: 45, weight: .regular)
        label.text = "---"
        return label
    }()
    
    private let valueLabelInMmol = BgLabelInMmol()
    
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
        
        let outerCircleRadius: CGFloat = 70

        slopPointerLayer.path = UIBezierPath(roundedRect: CGRect(origin: .zero,
                                                                 size: CGSize(width: outerCircleRadius,
                                                                              height: outerCircleRadius)),
                                             cornerRadius: 5).cgPath
        slopPointerLayer.fillColor = ConstantsUI.contentBackgroundColor.cgColor
        slopPointerLayer.frame = CGRect(origin: boundsCenter, size: CGSize(width: outerCircleRadius, height: outerCircleRadius))
        
        slopPointerInnerLayer.backgroundColor = GlucoseIndicator.InnerCircleBgNoValueColor.cgColor
        slopPointerInnerLayer.cornerRadius = 5
        let slopPointerLineWidth: CGFloat = 8
        slopPointerInnerLayer.frame = CGRect(origin: CGPoint(x: slopPointerLineWidth, y: slopPointerLineWidth),
                                             size: CGSize(width: outerCircleRadius - slopPointerLineWidth * 2,
                                                          height: outerCircleRadius - slopPointerLineWidth * 2))
        slopPointerLayer.addSublayer(slopPointerInnerLayer)
        layer.addSublayer(slopPointerLayer)
        
        slopPointerLayer.anchorPoint = .zero
        slopPointerLayer.transform = CATransform3DMakeRotation(-45 / 180.0 * .pi, 0, 0, 1)
        slopPointerLayer.isHidden = true
        
        var circlePathArea = CGRect(origin: .zero, size: CGSize(width: outerCircleRadius * 2, height: outerCircleRadius * 2))
        outerCircleBgLayer.path = UIBezierPath(ovalIn: circlePathArea).cgPath
        outerCircleBgLayer.fillColor = ConstantsUI.contentBackgroundColor.cgColor
        outerCircleBgLayer.frame = CGRect(center: boundsCenter, radius: outerCircleRadius)
        layer.addSublayer(outerCircleBgLayer)
        
        let innerCircleRadius: CGFloat = 60
        circlePathArea = CGRect(origin: .zero, size: CGSize(width: innerCircleRadius * 2, height: innerCircleRadius * 2))
        innerCircleBgLayer.path = UIBezierPath(ovalIn: circlePathArea).cgPath
        innerCircleBgLayer.fillColor = GlucoseIndicator.InnerCircleBgNoValueColor.cgColor
        innerCircleBgLayer.strokeColor = ConstantsUI.mainBackgroundColor.cgColor
        innerCircleBgLayer.lineWidth = 3
        innerCircleBgLayer.frame = CGRect(center: boundsCenter, radius: innerCircleRadius)
        layer.addSublayer(innerCircleBgLayer)
        
        addSubview(valueLabelMgDl)
        addSubview(valueLabelInMmol)
        addSubview(unitLabel)
        
        valueLabelMgDl.snp.makeConstraints { (make) in
            make.centerX.equalTo(self.snp.centerX)
            make.centerY.equalTo(self.snp.centerY).offset(-10)
        }
        
        valueLabelInMmol.snp.makeConstraints { make in
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
        
        slopPointerLayer.frame.origin = boundsCenter
        outerCircleBgLayer.frame.origin = CGPoint(x: boundsCenter.x - outerCircleBgLayer.bounds.size.width / 2,
                                                  y: boundsCenter.y - outerCircleBgLayer.bounds.size.height / 2)
        innerCircleBgLayer.frame.origin = CGPoint(x: boundsCenter.x - innerCircleBgLayer.bounds.size.width / 2,
                                                  y: boundsCenter.y - innerCircleBgLayer.bounds.size.height / 2)
    }
}

class BgLabelInMmol: UIView {
 
    private let valueLabelMmolInt: UILabel = {
        let label = UILabel()
        label.textColor = ConstantsUI.contentBackgroundColor
        label.font = .monospacedDigitSystemFont(ofSize: 50, weight: .bold)
        return label
    }()
    
    private let valueLabelMmolFraction: UILabel = {
        let label = UILabel()
        label.textColor = ConstantsUI.contentBackgroundColor
        label.font = .monospacedDigitSystemFont(ofSize: 30, weight: .regular)
        return label
    }()
    
    var bgValueInMmol: Double? {
        didSet {
            if let bgValueInMmol = bgValueInMmol {
                let intValue = Int((bgValueInMmol * 10).rounded()) / 10
                let fractionValue = Int((bgValueInMmol * 10).rounded()) % 10
                
                valueLabelMmolInt.text = "\(intValue)."
                valueLabelMmolFraction.text = "\(fractionValue)"
                
            } else {
                valueLabelMmolInt.text = nil
                valueLabelMmolFraction.text = nil
            }
            invalidateIntrinsicContentSize()
        }
    }
    
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
        addSubview(valueLabelMmolInt)
        addSubview(valueLabelMmolFraction)
        
        valueLabelMmolInt.snp.makeConstraints { make in
            make.centerY.equalToSuperview()
            make.left.equalToSuperview()
        }
        
        valueLabelMmolFraction.snp.makeConstraints { make in
            make.left.equalTo(valueLabelMmolInt.snp.right)
            make.bottom.equalTo(valueLabelMmolInt).offset(-5)
        }
    }
    
    public override var intrinsicContentSize: CGSize {
        let width = valueLabelMmolInt.intrinsicContentSize.width + valueLabelMmolFraction.intrinsicContentSize.width
        let height = valueLabelMmolInt.intrinsicContentSize.height
        return CGSize(width: width, height: height)
    }
}
