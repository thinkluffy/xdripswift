//
//  SensorCountdown.swift
//  xdrip
//
//  Created by Yuanbin Cai on 2021/12/11.
//  Copyright © 2021 Johan Degraeve. All rights reserved.
//

import UIKit
import CryptoKit

class SensorCountdown: UIView {
    
    private static let log = Log(type: SensorCountdown.self)
    
    private let blockGap: CGFloat = 3
    private let blockHeight: CGFloat = 4
    private let totalHoursInHoursMode = 12
    private let keptBlocksForTextInHoursMode = 2
    
    private var hoursMode = false
    
    private lazy var hoursRemainingTextLayer: CATextLayer = {
        let layer = VerticalCenterTextLayer()
        layer.foregroundColor = UIColor.white.cgColor
        layer.fontSize = 12
        layer.alignmentMode = .center
        layer.contentsScale = UIScreen.main.scale
        return layer
    }()
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        initialize()
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        initialize()
    }
    
    private func initialize() {
        backgroundColor = .clear
    }
    
    override func prepareForInterfaceBuilder() {
        initialize()
    }
    
    func show(maxSensorAgeInSeconds: Double, sensorStartDate: Date) {
        SensorCountdown.log.d("==> show, maxSensorAgeInSeconds: \(maxSensorAgeInSeconds), sensorStartDate: \(sensorStartDate)")
                
        let sensorAge = Date().timeIntervalSince(sensorStartDate)
        let hoursRemaining = Int(((maxSensorAgeInSeconds - sensorAge) / Date.hourInSeconds).rounded(.up))
        
        SensorCountdown.log.d("hoursRemaining: \(hoursRemaining)")
        
        if hoursRemaining <= 0 {
            SensorCountdown.log.e("hours remaining is smaller than 0, hoursRemaining: \(hoursRemaining)")
            isHidden = true
            return
        }
        
        isHidden = false
        
        if hoursRemaining <= totalHoursInHoursMode {
            showHoursMode(hoursRemaining: hoursRemaining)
            
        } else {
            showDaysMode(maxSensorAgeInSeconds: maxSensorAgeInSeconds, hoursRemaining: hoursRemaining)
        }
    }
    
    private func showHoursMode(hoursRemaining: Int) {
        SensorCountdown.log.d("==> showHoursMode")
        
        if !hoursMode {
            hoursMode = true
            layer.sublayers?.forEach { $0.removeFromSuperlayer() }
        }
        
        let blockCount = totalHoursInHoursMode
        let blockWidth = (bounds.width + blockGap) / CGFloat(blockCount + keptBlocksForTextInHoursMode) - blockGap
        let blockY = (bounds.height - blockHeight) / 2
        
        if layer.sublayers == nil {
            for i in 0 ..< blockCount {
                let blockLayer = CALayer()
                
                blockLayer.frame = CGRect(x: (blockWidth + blockGap) * CGFloat(i),
                                          y: blockY,
                                          width: blockWidth,
                                          height: blockHeight)
                
                layer.addSublayer(blockLayer)
            }
            
            hoursRemainingTextLayer.frame = CGRect(x: (blockWidth + blockGap) * Double(blockCount),
                                                   y: 0,
                                                   width: blockWidth * 2,
                                                   height: bounds.height)
            layer.addSublayer(hoursRemainingTextLayer)
        }
        
        let highlightColor = hoursRemaining <= 3 ? ConstantsGlucoseChart.glucoseUrgentRangeColor : ConstantsGlucoseChart.glucoseNotUrgentRangeColor
        
        guard let sublayers = layer.sublayers else {
            return
        }
        
        for (i, layer) in sublayers.enumerated() {
            if i >= blockCount {
                break
            }
            
            if i < hoursRemaining {
                layer.backgroundColor = highlightColor.cgColor
                
            } else {
                layer.backgroundColor = ConstantsUI.tabBarBackgroundColor.cgColor
            }
        }
        
        hoursRemainingTextLayer.string = "\(hoursRemaining) H"
    }
    
    private func showDaysMode(maxSensorAgeInSeconds: Double, hoursRemaining: Int) {
        SensorCountdown.log.d("==> showDaysMode")

        if hoursMode {
            hoursMode = false
            layer.sublayers?.forEach { $0.removeFromSuperlayer() }
        }
        
        let maxDays = Int((maxSensorAgeInSeconds / Date.dayInSeconds).rounded(.up))
        let daysRemaining = Int((Double(hoursRemaining) / Date.dayInSeconds).rounded(.up))
        SensorCountdown.log.d("maxDays: \(maxDays), daysRemaining: \(daysRemaining)")

        let blockWidth = (bounds.width + blockGap) / CGFloat(maxDays) - blockGap
        let blockY = (bounds.height - blockHeight) / 2

        if layer.sublayers == nil || layer.sublayers?.count != maxDays {
            layer.sublayers?.forEach { $0.removeFromSuperlayer() }

            for i in 0 ..< maxDays {
                let blockLayer = CALayer()
                
                blockLayer.frame = CGRect(x: (blockWidth + blockGap) * CGFloat(i),
                                          y: blockY,
                                          width: blockWidth,
                                          height: blockHeight)
                
                layer.addSublayer(blockLayer)
            }
        }

        let highlightColor: UIColor = daysRemaining <= 1 ? ConstantsGlucoseChart.glucoseNotUrgentRangeColor : .gray

        guard let layers = layer.sublayers else {
            return
        }
        
        for (i, layer) in layers.enumerated() {
            if i < daysRemaining {
                layer.backgroundColor = highlightColor.cgColor
                
            } else {
                layer.backgroundColor = ConstantsUI.tabBarBackgroundColor.cgColor
            }
        }
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        guard let sublayers = layer.sublayers else {
            return
        }
        
        let blockY = (bounds.height - blockHeight) / 2
        
        if hoursMode {
            let blockCount = totalHoursInHoursMode
            let blockWidth = (bounds.width + blockGap) / CGFloat(blockCount + keptBlocksForTextInHoursMode) - blockGap
            
            for (i, layer) in sublayers.enumerated() {
                if i < blockCount {
                    layer.frame = CGRect(x: (blockWidth + blockGap) * CGFloat(i),
                                         y: blockY,
                                         width: blockWidth,
                                         height: blockHeight)
                }
            }
            
            hoursRemainingTextLayer.frame = CGRect(x: (blockWidth + blockGap) * Double(blockCount),
                                                   y: 0,
                                                   width: blockWidth * 2,
                                                   height: bounds.height)
            
        } else {
            let blockWidth = (bounds.width + blockGap) / CGFloat(sublayers.count) - blockGap
            
            for (i, layer) in sublayers.enumerated() {
                layer.frame = CGRect(x: (blockWidth + blockGap) * CGFloat(i),
                                     y: blockY,
                                     width: blockWidth,
                                     height: blockHeight)
            }
        }
    }
}
