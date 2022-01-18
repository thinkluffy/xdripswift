//
//  DailyTrend.swift
//  zDrip
//
//  Created by Liu Xudong on 2022/1/6.
//  Copyright © 2022 zDrip. All rights reserved.
//

import Foundation

class DailyTrend {

	private static let MinValidDataCount: Int = 5
	
    struct DailyTrendItem {

        init(timeInterval: TimeInterval) {
            self.timeInterval = timeInterval
        }

        // unit: Minutes, TimeInterval from 00:00
        var timeInterval: TimeInterval

        var isValid: Bool {
            values.count >= MinValidDataCount
        }
		

        // default unit of coredata, mg/dl
        private(set) var values: [Double] = []

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
    ///
    /// - Returns nil if not enough data
    ///     value: (list, availableDays)?
    static func calculate(_ history: [BgReading],
                          minutesInterval: Int = 5) -> ([DailyTrendItem], Double)? {
        guard history.count > 0 else {
            return nil
        }

        var result: [DailyTrendItem] = []

        // separate one day to groups with minutesInterval
        for minutesIndex in stride(from: 0, to: 24 * 60 + 1, by: minutesInterval) {
            result.append(DailyTrendItem(timeInterval: TimeInterval(minutesIndex * 60)))
        }

		var dayRangeIndexMapValues: [String: [Double]] = [:]
        for bg in history {
            let date = bg.timeStamp
            let value = bg.calculatedValue
			let month = Calendar.current.component(Calendar.Component.month, from: date)
            let day = Calendar.current.component(Calendar.Component.day, from: date)
            let hour = Calendar.current.component(Calendar.Component.hour, from: date)
            let minute = Calendar.current.component(Calendar.Component.minute, from: date)
            let minuteIndex = (hour * 60 + minute + minutesInterval / 2) / minutesInterval
			let key = "\(month)_\(day)_\(minuteIndex)"
			if let values = dayRangeIndexMapValues[key] {
				dayRangeIndexMapValues[key] = values + [value]
                
			} else {
				dayRangeIndexMapValues[key] = [value]
			}
		}
        
		// only pick add one data in one timeRange for each day
		for (key, values) in dayRangeIndexMapValues {
			let comps = key.components(separatedBy: "_")
			let index = Int(comps.last!)!
			let value = values.reduce(0, {$0 + $1}) / Double(values.count) // average
			if index == 0 || index == (result.count - 1) {
				result[0].appendValue(value)
				result[result.count - 1].appendValue(value)

            } else {
                result[index].appendValue(value)
            }
        }

		let daysDataCount = result.reduce(0, { $0 + $1.values.count })
		let availableDay = Double(daysDataCount) / Double(result.count)
		if availableDay > Double(MinValidDataCount) {
            for i in result.indices {
                result[i].calculateValues()
            }
            return (result, availableDay)

        } else {
            return nil
        }
    }
}
