//
//  DailyTrend.swift
//  zDrip
//
//  Created by Liu Xudong on 2022/1/6.
//  Copyright © 2022 zDrip. All rights reserved.
//

import Foundation

class DailyTrend {

    struct DailyTrendItem {

        init(timeInterval: TimeInterval) {
            self.timeInterval = timeInterval
        }

        // unit: Minutes, TimeInterval from 00:00
        var timeInterval: TimeInterval

        var isValid: Bool {
            get {
                values.count >= 5
            }
        }

        // default unit of coredata, mg/dl
        private var values: [Double] = []

        private(set) var high: Double? = nil
        private(set) var medianHigh: Double? = nil
        private(set) var median: Double? = nil
        private(set) var medianLow: Double? = nil
        private(set) var low: Double? = nil

        mutating func appendValue(_ value: Double) {
            values.append(value)
        }

        mutating func calculateValues() {
            guard isValid else {
                return
            }

			/// return: (result value, from index, end index)
			func median(of array: [Double], at percent: Double) -> Double? {
				guard array.count > 1 else {
					return nil
				}
				
				guard percent >= 0 && percent <= 1 else {
					return nil
				}
				let percentIndex = Double(array.count - 1) * percent
				let startIndex = floor(percentIndex)
				let endIndex = ceil(percentIndex)
				let offset: Double = Double((Int(round(Double(array.count + 1) * percent * 10)) % 10)) / 10
				let start = array[Int(startIndex)]
				let end = array[Int(endIndex)]
				let result: Double = start + (end - start) * offset
				return result
			}

            values.sort(by: >)
            if let h = median(of: values, at: 0.1),
               let mh = median(of: values, at: 0.25),
               let m = median(of: values, at: 0.5),
               let ml = median(of: values, at: 0.75),
               let l = median(of: values, at: 0.9) {
                high = h
                medianHigh = mh
                self.median = m
                medianLow = ml
                low = l
            }
        }
    }

    // Example:
    // last 90 days
//	BgReadingsAccessor().getBgReadingsAsync(
//		   from: Date().addingTimeInterval(-Double(90 * 24 * 60 * 60)),
//		   to: Date())
//	   { list in
//		   if let list = list {
//			// Interval is 5 minutes
//			   _ = DailyPattern.calculate(list, 5)
//		   }
//	   }

    /// history: data list, normally recently 90 days
    /// minutesInterval: separate one day to groups with min Interval in minutes
    /// returned value: (startDate, endDate, list)?
    static func calculate(_ history: [BgReading],
                          minutesInterval: Int = 5) -> (Date, Date, [DailyTrendItem])? {
        guard history.count > 0 else {
            return nil
        }

        var startDate: Date?
        var endDate: Date?
        var result: [DailyTrendItem] = []

        // separate one day to groups with minutesInterval
        for minutesIndex in stride(from: 0, to: 24 * 60, by: minutesInterval) {
            result.append(DailyTrendItem(timeInterval: TimeInterval(minutesIndex * 60)))
        }

        var lastIndex: Int?
        var lastDay: Int?
        for bg in history {
            let date = bg.timeStamp
            let value = bg.calculatedValue
            let day = Calendar.current.component(Calendar.Component.day, from: date)
            let hour = Calendar.current.component(Calendar.Component.hour, from: date)
            let minute = Calendar.current.component(Calendar.Component.minute, from: date)
            let minuteIndex = hour * 60 / minutesInterval + minute / minutesInterval
            // only pick up one data in one timeRange each day
            if minuteIndex == lastIndex && day == lastDay {
                continue

            } else {
                lastIndex = minuteIndex
                lastDay = day
                result[minuteIndex].appendValue(value)

                if startDate == nil || startDate! > date {
                    startDate = date
                }

                if endDate == nil || endDate! < date {
                    endDate = date
                }
            }
        }

        if let startDate = startDate,
           let endDate = endDate {
            for i in result.indices {
                result[i].calculateValues()
            }
            return (startDate, endDate, result)

        } else {
            return nil
        }
    }
}
