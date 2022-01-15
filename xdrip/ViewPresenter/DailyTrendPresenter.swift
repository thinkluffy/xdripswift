//
//  DailyTrendPresenter.swift
//  xdrip
//
//  Created by Yuanbin Cai on 2022/1/10.
//  Copyright © 2022 zDrip. All rights reserved.
//

import UIKit

class DailyTrendPresenter: DailyTrendP {

    private static let log = Log(type: DailyTrendPresenter.self)

    private weak var view: DailyTrendV?

    private let bgReadingsAccessor = BgReadingsAccessor()

    init(view: DailyTrendV) {
        self.view = view
    }

    func loadData(of date: Date, withDays daysRange: Int) {
        let toDate = Calendar.current.startOfDay(for: date) // 00:00 of the day
        let fromDate = Date(timeInterval: -Date.dayInSeconds * Double(daysRange), since: toDate)

        DispatchQueue.global(qos: .userInteractive).async {
            let moc = CoreDataManager.shared.privateChildManagedObjectContext()
            
            moc.performAndWait {
                let readings = self.bgReadingsAccessor.getBgReadings(from: fromDate, to: toDate, on: moc)

                guard let (startDate, endDate, dailyTrendItems) = DailyTrend.calculate(readings, minutesInterval: 10) else {
                    DispatchQueue.main.async {
                        self.view?.showNoEnoughData(ofDate: date)
                    }
                    return
                }

                DispatchQueue.main.async {
                    self.view?.showDailyTrend(ofDate: date,
                                              startDateOfData: startDate,
                                              endDateOfData: endDate,
                                              dailyTrendItems: dailyTrendItems)
                }
            }
        }
    }
}
