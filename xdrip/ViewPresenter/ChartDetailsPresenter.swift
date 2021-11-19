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
    
    func loadData(date: Date) {
        if coreDataManager != nil {
            doLoadData(date: date)
            
        } else {
            coreDataManager = CoreDataManager(modelName: ConstantsCoreData.modelName) { [weak self] in
                self?.doLoadData(date: date)
            }
        }
    }
    
    private func doLoadData(date: Date) {
        guard let coreDataManager = coreDataManager else {
            return
        }
        
        if bgReadingAccessor == nil {
            bgReadingAccessor = BgReadingsAccessor(coreDataManager: coreDataManager)
        }
        
        DispatchQueue.global(qos: .userInteractive).async { [weak self] in
            let fromDate = Calendar.current.startOfDay(for: date)
            let components = DateComponents(hour: 23, minute: 59, second: 59)
            let toDate = Calendar.current.date(byAdding: components, to: fromDate)!
            
            let readings = self?.bgReadingAccessor!.getBgReadings(from: fromDate,
                                                                  to: toDate,
                                                                  on: coreDataManager.mainManagedObjectContext)
           
            DispatchQueue.main.async {
                self?.view?.showReadings(readings, from: fromDate, to: toDate)
            }
        }
    }
}
