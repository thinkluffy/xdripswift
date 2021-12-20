//
//  NotesPresenter.swift
//  xdrip
//
//  Created by Yuanbin Cai on 2021/12/18.
//  Copyright © 2021 Johan Degraeve. All rights reserved.
//

import Foundation

class NotesPresenter: NotesP {
  
    private static let log = Log(type: NotesPresenter.self)

    private weak var view: NotesV?
    
    init(view: NotesV) {
        self.view = view
    }
    
    func loadData(date: Date) {
        DispatchQueue.global(qos: .userInteractive).async { [weak self] in
//            let fromDate = Calendar.current.startOfDay(for: date)
//            let toDate = Date(timeInterval: Date.dayInSeconds, since: fromDate)
//
//            let readings = self?.bgReadingsAccessor.getBgReadings(from: fromDate,
//                                                                  to: toDate,
//                                                                  on: CoreDataManager.shared.mainManagedObjectContext)
//
            DispatchQueue.main.async {
//                self?.view?.show(readings: readings, from: fromDate, to: toDate)
            }
        }
    }
}
