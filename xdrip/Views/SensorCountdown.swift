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
    
    func show(maxSensorAgeInSeconds: Int, sensorStartDate: Date) {
        SensorCountdown.log.d("==> show, maxSensorAgeInSeconds: \(maxSensorAgeInSeconds), sensorStartDate: \(sensorStartDate)")
                
        let maxDays = Int(Double(maxSensorAgeInSeconds) / Date.dayInSeconds)
        let blockWidth = (bounds.width + blockGap) / CGFloat(maxDays) - blockGap
        let blockHeight = bounds.height

        if layer.sublayers == nil || layer.sublayers?.count != maxDays {
            layer.sublayers?.forEach { $0.removeFromSuperlayer() }

            for i in 0 ..< maxDays {
                let blockLayer = CALayer()
                
                blockLayer.backgroundColor = ConstantsUI.tabBarBackgroundColor.cgColor
                blockLayer.frame = CGRect(x: (blockWidth + blockGap) * CGFloat(i),
                                          y: 0,
                                          width: blockWidth,
                                          height: blockHeight)
                
                layer.addSublayer(blockLayer)
            }
        }
        
        updateDaysRemaining(maxSensorAgeInDays: maxDays, sensorStartDate: sensorStartDate)
    }
    
    private func updateDaysRemaining(maxSensorAgeInDays: Int, sensorStartDate: Date) {
        // calculate how many hours the sensor has been used for since starting. We need to use hours instead of days because during the last day we need to see how many hours are left so that we can display the warning and urgent status graphics.
        let currentSensorAgeInHours: Int = Calendar.current.dateComponents([.hour], from: sensorStartDate - 5 * 60, to: Date()).hour!
        
        // we need to calculate the hours so that we can see if we need to show the yellow (<12hrs remaining) or red (<6hrs remaining) graphics
        let sensorCountdownHoursRemaining: Int = (maxSensorAgeInDays * 24) - currentSensorAgeInHours
        
        // start programatically creating the asset name that we will loaded. This is based upon the max sensor days and the days "remaining". To get the full days, we need to round up the currentSensorAgeInHours to the nearest 24 hour block
        let daysRemaining: Int
        let highlightColor: UIColor
        
        // find the amount of days remaining and add it to the asset name string. If there is less than 12 hours, add the corresponding warning/urgent label. If the sensor hours remaining is 0 or less, then the sensor is either expired or in the last 12 hours of "overtime" (e.g Libre sensors have an extra 12 hours before the stop working). If this happens, then instead of appending the days left, always show the "00" graphic.
        if sensorCountdownHoursRemaining > 0 {
            daysRemaining = maxSensorAgeInDays - Int(round(Double(currentSensorAgeInHours / 24)) * 24) / 24
            
            switch sensorCountdownHoursRemaining {
            case 7...12:
                highlightColor = ConstantsGlucoseChart.glucoseNotUrgentRangeColor
                
            case 1...6:
                highlightColor = ConstantsGlucoseChart.glucoseUrgentRangeColor
                
            default:
                highlightColor = .gray
            }
            
        } else {
            daysRemaining = 0
            highlightColor = ConstantsGlucoseChart.glucoseUrgentRangeColor
        }
        
        if let blocks = layer.sublayers {
            if daysRemaining > 0 {
                for i in 0 ..< daysRemaining {
                    blocks[i].backgroundColor = highlightColor.cgColor
                }
                
            } else {
                for block in blocks {
                    block.backgroundColor = highlightColor.cgColor
                }
            }
        }
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        guard let blocks = layer.sublayers else {
            return
        }
        
        let blockWidth = (bounds.width + blockGap) / CGFloat(blocks.count) - blockGap
        let blockHeight = bounds.height
        
        for (i, block) in blocks.enumerated() {
            block.frame = CGRect(x: (blockWidth + blockGap) * CGFloat(i),
                                 y: 0,
                                 width: blockWidth,
                                 height: blockHeight)
        }
    }
}
