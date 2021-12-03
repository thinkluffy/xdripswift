//
//  ChartDetailsContract.swift
//  xdrip
//
//  Created by Yuanbin Cai on 2021/11/15.
//  Copyright © 2021 Johan Degraeve. All rights reserved.
//

import UIKit

protocol ChartDetailsV: MVPV {
    
    func show(readings: [BgReading]?, from fromDate: Date, to toDate: Date)
    
    func show(statistics: StatisticsManager.Statistics, of date: Date)
}

protocol ChartDetailsP: MVPP {
    
    func loadData(date: Date)
    
    func loadStatistics(date: Date)
}
