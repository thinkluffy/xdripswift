//
//  DailyTrendContract.swift
//  xdrip
//
//  Created by Yuanbin Cai on 2022/1/10.
//  Copyright © 2022 zDrip. All rights reserved.
//

import UIKit

protocol DailyTrendV: MVPV {
    
//    func show(readings: [BgReading]?, from fromDate: Date, to toDate: Date)
    
}

protocol DailyTrendP: MVPP {
    
    func loadData(of date: Date, withDays daysRange: Int)
    
}
