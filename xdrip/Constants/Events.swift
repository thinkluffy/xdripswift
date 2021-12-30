//
//  Events.swift
//  xdrip
//
//  Created by Yuanbin Cai on 2021/12/30.
//  Copyright © 2021 Johan Degraeve. All rights reserved.
//

import Foundation

enum Events {

    // MARK: - performance events
    
    static let processNewGlucoseData = "ProcessNewGlucoseData"

    // MARK: - analytics events

    static let prefixBgAlert = "bgAlert_"
    
    static let prefixNewSensor = "newSensor_"
}
