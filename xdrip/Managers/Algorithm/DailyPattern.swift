//
//  DailyPattern.swift
//  xdrip
//
//  Created by Liu Xudong on 2022/1/6.
//  Copyright © 2022 zDrip. All rights reserved.
//

import Foundation

class DailyPattern {
	
	struct DailyPatternItem {
		// unit: Minutes, TimeInterval from 00:00
		var timeInterval: TimeInterval
		
		// default unit of coredata, mg/dl
		var values: [Double] = []
		var high: Double?
		var medianHigh: Double?
		var median: Double?
		var medianLow: Double?
		var low: Double?
		
		mutating func appendValue(_ value: Double) {
			self.values.append(value)
		}
		
		mutating func calculateValues() {
			guard values.count > 0 else {
				return
			}
			/// return: (result value, from index, end index)
			func median(of array: [Double]) -> (Double, Int, Int)? {
				guard array.count > 0 else { return nil }
				
				if array.count % 2 == 0 {
					let end = array.count / 2
					let start = end - 1
					return ((array[start] + array[end]) / 2, start, end)
				} else {
					let index = (array.count - 1) / 2
					return (array[index], index, index)
				}
			}
			self.values.sort(by: >)
			self.high = self.values.first!
			self.low = self.values.last!
			if let (value, start, end) = median(of: values) {
				self.median = value
				self.medianHigh = median(of: Array(values[0...end]))?.0
				self.medianLow = median(of: Array(values[start..<values.count]))?.0
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
	/// retured value: (startDate, endDate, list)?
	static func calculate(_ history: [BgReading],
						  _ minutesInterval: Int) -> (Date, Date, [DailyPatternItem])? {
		guard history.count > 0 else {
			return nil
		}
		var startDate: Date?
		var endDate: Date?
		var result: [DailyPatternItem] = []
		// separate one day to groups with minutesInterval
		for minutesIndex in stride(from: 0, to: 24*60, by: minutesInterval) {
			result.append(DailyPatternItem(timeInterval: TimeInterval(minutesIndex)))
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
