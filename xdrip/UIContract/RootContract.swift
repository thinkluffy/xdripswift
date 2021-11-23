//
//  RootContract.swift
//  xdrip
//
//  Created by Yuanbin Cai on 2021/11/22.
//  Copyright © 2021 Johan Degraeve. All rights reserved.
//

import UIKit

protocol RootV: MVPV {
    
    func showNewReading()
}

protocol RootP: MVPP {
    
    // temp used during refactoring
    func setup(coreDataManager: CoreDataManager,
               bgReadingsAccessor: BgReadingsAccessor,
               healthKitManager: HealthKitManager,
               bgReadingSpeaker: BGReadingSpeaker,
               watchManager: WatchManager,
               bluetoothPeripheralManager: BluetoothPeripheralManager,
               loopManager: LoopManager)
}
