//
//  RootContract.swift
//  xdrip
//
//  Created by Yuanbin Cai on 2021/11/22.
//  Copyright © 2021 Johan Degraeve. All rights reserved.
//

import UIKit

protocol RootV: MVPV {
    
    func showNewFollowerReading()
    
    func showChartReadings(_ readings: [BgReading]?, from fromDate: Date, to toDate: Date)
}

protocol RootP: MVPP {
    
    // temp used during refactoring
    func setup(bgReadingsAccessor: BgReadingsAccessor,
               healthKitManager: HealthKitManager,
               bgReadingSpeaker: BGReadingSpeaker,
               bluetoothPeripheralManager: BluetoothPeripheralManager,
               loopManager: LoopManager)
    
    func loadChartReadings()
}