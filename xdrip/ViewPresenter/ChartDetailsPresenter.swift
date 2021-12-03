//
//  ChartDetailsPresenter.swift
//  xdrip
//
//  Created by Yuanbin Cai on 2021/11/15.
//  Copyright © 2021 Johan Degraeve. All rights reserved.
//

import UIKit

class ChartDetailsPresenter: ChartDetailsP {
  
    private static let log = Log(type: ChartDetailsPresenter.self)

    private weak var view: ChartDetailsV?
    
    private let bgReadingsAccessor = BgReadingsAccessor()
    private let statisticsManager = StatisticsManager()

    init(view: ChartDetailsV) {
        self.view = view
    }
    
    func loadData(date: Date) {
        DispatchQueue.global(qos: .userInteractive).async { [weak self] in
            let fromDate = Calendar.current.startOfDay(for: date)
            let toDate = Date(timeInterval: Date.dayInSeconds, since: fromDate)
            
            let readings = self?.bgReadingsAccessor.getBgReadings(from: fromDate,
                                                                  to: toDate,
                                                                  on: CoreDataManager.shared.mainManagedObjectContext)
           
            DispatchQueue.main.async {
                self?.view?.show(readings: readings, from: fromDate, to: toDate)
            }
        }
    }
    
    func loadStatistics(date: Date) {
        let fromDate = Calendar.current.startOfDay(for: date)
        let toDate = Date(timeInterval: Date.dayInSeconds, since: fromDate)
        
        statisticsManager.calculateStatistics(fromDate: fromDate, toDate: toDate, callback: { [weak self] statistics in
            self?.view?.show(statistics: statistics, of: date)
        })
    }
}
