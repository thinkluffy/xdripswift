//
//  ChartDetailsContract.swift
//  xdrip
//
//  Created by Yuanbin Cai on 2021/11/15.
//  Copyright © 2021 Johan Degraeve. All rights reserved.
//

import UIKit

protocol ChartDetailsV: MVPV {
    
    func showReadings(_ readings: [BgReading]?, from fromDate: Date, to toDate: Date)
}

protocol ChartDetailsP: MVPP {
    
    func loadData(date: Date)
    
}
