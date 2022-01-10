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
//        let fromDate = Calendar.current.startOfDay(for: date)
//        let toDate = Date(timeInterval: Date.dayInSeconds, since: fromDate)
//
//        bgReadingsAccessor.getBgReadingsAsync(from: fromDate, to: toDate) {
//            [weak self] bgReadings in
//            self?.view?.show(readings: bgReadings, from: fromDate, to: toDate)
//        }
    }
}
