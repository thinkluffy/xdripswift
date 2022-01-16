//
//  Constants.swift
//  xdrip
//
//  Created by Yuanbin Cai on 2021/11/27.
//  Copyright © 2021 Johan Degraeve. All rights reserved.
//

import Foundation

enum ChartHours: Int {
    
    case h1 = 1
    case h3 = 3
    case h6 = 6
    case h12 = 12
    case h24 = 24
}

enum ChartDays: Int {

    case today = 0
    case day7 = 7
    case day14 = 14
    case day30 = 30
    case day90 = 90
}

enum Constants {
    
    /// how often to update the labels in the homeview (ie label with latest reading, minutes ago, etc..)
    static let updateHomeViewIntervalInSeconds = 30.0
    
    static let minsToCalculateSlope = 10
    
    static let bgUnitMgDl = "mg/dL"
    static let bgUnitMmol = "mmol/L"
    
    static let minBgMgDl: Double = 40 // 2.2 mmol/L
    static let maxBgMgDl: Double = 540 // 30 mmmol/L
    
    static let privacyPolicyUrl = "https://getcallapps.github.io/zdrip/privacy_policy"
}


enum EventBusEvents {
    
    static let snoozeAlertsStatusChanged = "snoozeAlertsStatusChanged"
    static let newNote = "newNote"
}
