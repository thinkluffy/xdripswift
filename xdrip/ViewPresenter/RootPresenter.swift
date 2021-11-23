//
//  RootPresenter.swift
//  xdrip
//
//  Created by Yuanbin Cai on 2021/11/22.
//  Copyright © 2021 Johan Degraeve. All rights reserved.
//

import UIKit

class RootPresenter: RootP {

    private static let log = Log(type: RootPresenter.self)

    private weak var view: RootV?
    
    private var coreDataManager: CoreDataManager?
    
    private var bgReadingsAccessor: BgReadingsAccessor?
    private var healthKitManager: HealthKitManager?
    private var bgReadingSpeaker: BGReadingSpeaker?
    private var watchManager: WatchManager?
    private var bluetoothPeripheralManager: BluetoothPeripheralManager?
    private var loopManager: LoopManager?
    
    private var nightScoutFollowManager: NightScoutFollowManager?

    init(view: RootV) {
        self.view = view
    }
    
    func setup(coreDataManager: CoreDataManager,
               bgReadingsAccessor: BgReadingsAccessor,
               healthKitManager: HealthKitManager,
               bgReadingSpeaker: BGReadingSpeaker,
               watchManager: WatchManager,
               bluetoothPeripheralManager: BluetoothPeripheralManager,
               loopManager: LoopManager) {
        self.coreDataManager = coreDataManager
        self.bgReadingsAccessor = bgReadingsAccessor
        self.healthKitManager = healthKitManager
        self.bgReadingSpeaker = bgReadingSpeaker
        self.watchManager = watchManager
        self.bluetoothPeripheralManager = bluetoothPeripheralManager
        self.loopManager = loopManager
        
        nightScoutFollowManager = NightScoutFollowManager(coreDataManager: coreDataManager,
                                                          nightScoutFollowerDelegate: self)
    }
    
    // a long function just to get the timestamp of the last disconnect or reconnect. If not known then returns 1 1 1970
    private func lastConnectionStatusChangeTimeStamp() -> Date  {
        // this is actually unwrapping of optionals, goal is to get date of last disconnect/reconnect - all optionals should exist so it doesn't matter what is returned true or false
        guard let cgmTransmitter = bluetoothPeripheralManager?.getCGMTransmitter(),
                let bluetoothTransmitter = cgmTransmitter as? BluetoothTransmitter,
                let bluetoothPeripheral = bluetoothPeripheralManager?.getBluetoothPeripheral(for: bluetoothTransmitter),
                let lastConnectionStatusChangeTimeStamp = bluetoothPeripheral.blePeripheral.lastConnectionStatusChangeTimeStamp
        else {
            return Date(timeIntervalSince1970: 0)
        }
        
        return lastConnectionStatusChangeTimeStamp
    }
}

extension RootPresenter: NightScoutFollowerDelegate {
    
    func nightScoutFollowerInfoReceived(followGlucoseDataArray: inout [NightScoutBgReading]) {
        guard let coreDataManager = coreDataManager,
              let bgReadingsAccessor = bgReadingsAccessor,
              let nightScoutFollowManager = nightScoutFollowManager
        else {
            return
        }
        
        // assign value of timeStampLastBgReading
        var timeStampLastBgReading = Date(timeIntervalSince1970: 0)

        // get lastReading, ignore sensor as this should be nil because this is follower mode
        if let lastReading = bgReadingsAccessor.last(forSensor: nil) {
            timeStampLastBgReading = lastReading.timeStamp
        }
        
        // was a new reading created or not
        var newReadingCreated = false
        
        // iterate through array, elements are ordered by timestamp, first is the youngest, let's create first the oldest, although it shouldn't matter in what order the readings are created
        for (_, followGlucoseData) in followGlucoseDataArray.enumerated().reversed() {
            if followGlucoseData.timeStamp > timeStampLastBgReading {
                // creata a new reading
                _ = nightScoutFollowManager.createBgReading(followGlucoseData: followGlucoseData)
                
                // a new reading was created
                newReadingCreated = true
                
                // set timeStampLastBgReading to new timestamp
                timeStampLastBgReading = followGlucoseData.timeStamp
            }
        }
        
        if newReadingCreated {
            RootPresenter.log.d("nightScoutFollowerInfoReceived, new reading(s) received")
            
            coreDataManager.saveChanges()
            
            healthKitManager?.storeBgReadings()
            bgReadingSpeaker?.speakNewReading(lastConnectionStatusChangeTimeStamp: lastConnectionStatusChangeTimeStamp())
            bluetoothPeripheralManager?.sendLatestReading()
            
            // ask watchManager to process new reading, ignore last connection change timestamp because this is follower mode, there is no connection to a transmitter
            watchManager?.processNewReading(lastConnectionStatusChangeTimeStamp: nil)
            
            // send also to loopmanager, not interesting for loop probably, but the data is also used for today widget
            loopManager?.share()
            
            view?.showNewReading()
        }
    }
}
