//
//  DailyTrendContract.swift
//  xdrip
//
//  Created by Yuanbin Cai on 2022/1/10.
//  Copyright © 2022 zDrip. All rights reserved.
//

import UIKit

protocol DailyTrendV: MVPV {

    func showLoadingData()

    func showNoEnoughData(ofDate: Date)

    func showDailyTrend(ofDate date: Date,
                        withDaysRange daysRange: Int,
						validDays: Double,
                        dailyTrendItems: [DailyTrend.DailyTrendItem])
}

protocol DailyTrendP: MVPP {

    func loadData(of date: Date, withDays daysRange: Int)

}
