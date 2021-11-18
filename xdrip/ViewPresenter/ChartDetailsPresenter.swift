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
    
    private var coreDataManager: CoreDataManager?
    private var bgReadingAccessor: BgReadingsAccessor?
    
    init(view: ChartDetailsV) {
        self.view = view
    }
    
    func loadData() {
        if coreDataManager != nil {
            doLoadData()
            
        } else {
            coreDataManager = CoreDataManager(modelName: ConstantsCoreData.modelName) { [weak self] in
                self?.doLoadData()
            }
        }
    }
    
    private func doLoadData() {
        guard let coreDataManager = coreDataManager else {
            return
        }
        
        if bgReadingAccessor == nil {
            bgReadingAccessor = BgReadingsAccessor(coreDataManager: coreDataManager)
        }
        
        DispatchQueue.global(qos: .userInteractive).async { [weak self] in
            let fromDate = NSDate(timeIntervalSinceNow: -Date.hourInSeconds * 6) as Date
            let toDate = Date()
            let readings = self?.bgReadingAccessor!.getBgReadings(from: fromDate,
                                                                  to: toDate,
                                                                  on: coreDataManager.mainManagedObjectContext)
           
            DispatchQueue.main.async {
                self?.view?.showReadings(readings, from: fromDate, to: toDate)
            }
        }
    }
}
