//
//  Constants.swift
//  xdrip
//
//  Created by Yuanbin Cai on 2021/11/27.
//  Copyright © 2021 Johan Degraeve. All rights reserved.
//

import Foundation

enum ChartHours {
    
    static let H1 = 0
    static let H3 = 1
    static let H6 = 2
    static let H12 = 3
    static let H24 = 4
}


enum Constants {
    
    /// how often to update the labels in the homeview (ie label with latest reading, minutes ago, etc..)
    static let updateHomeViewIntervalInSeconds = 30.0
    
    static let minsToCalculateSlope = 10
    
    static let bgUnitMgDl = "mg/dL"
    static let bgUnitMmol = "mmol/L"
    
    static let maxBgMgDl = 540 // 30 mmmol/L
}
