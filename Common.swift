//
//  Common.swift
//  WatchApp WatchKit Extension
//
//  Created by Liu Xudong on 2021/10/29.
//

import Foundation

class Common {
	
	static let debugVersion: String = "9"
	
	enum MessageValues: String {
		case recently = "recently"
		case latest = "latest"
	}
	
	enum BgSlope: Int, CustomStringConvertible {
		case downDouble = -4
		case down = -2
		case downHalf = -1
		case flat = 0
		case upHalf = 1
		case up = 2
		case upDouble = 4
		
		var description: String {
			switch self {
			case .downDouble:
				return "\u{2193}\u{2193}"//"↘︎↘︎"
			case .down:
				return "\u{2193}"//"↘︎"
			case .downHalf:
				return "\u{2198}"//"⇣"
			case .flat:
				return "\u{2192}"//"→→"
			case .upHalf:
				return "\u{2197}"//"⇡"
			case .up:
				return "\u{2191}"//"↑"
			case .upDouble:
				return "\u{2191}\u{2191}"//"↑↑"
			}
		}
	}
	
	struct BgInfo {
		var date: Date
		var value: Double
		
		init(date: Date, value: Double) {
			self.date = date
			self.value = value
		}
		
		init(dic: [String: Any]) {
			guard let timeInterval = dic["timeInterval"] as? TimeInterval,
				  let value = dic["value"] as? Double
			else {
				fatalError("Date formatter Error")
			}
			self.date = Date(timeIntervalSince1970: timeInterval)
			self.value = value
		}
		
		func toDic() -> [String: Any] {
			return ["timeInterval": date.timeIntervalSince1970,
					"value": value]
		}
	}
	
	struct BgConfig {
		var interval5Mins: Bool
		var showAsMgDl: Bool
		var min: Double
		var max: Double
		var urgentMin: Double
		var urgentMax: Double
		var suggestMin: Double
		var suggestMax: Double
		
		init(interval5Mins: Bool,
			 showAsMgDl: Bool,
			 min: Double,
			 max: Double,
			 urgentMin: Double,
			 urgentMax: Double,
			 suggestMin: Double,
			 suggestMax: Double) {
			self.interval5Mins = interval5Mins
			self.showAsMgDl = showAsMgDl
			self.min = min
			self.max = max
			self.urgentMin = urgentMin
			self.urgentMax = urgentMax
			self.suggestMin = suggestMin
			self.suggestMax = suggestMax
		}
		
		init(dic: [String: Any]) {
			guard let interval5Mins = dic["interval5Mins"] as? Bool,
				  let showAsMgDl = dic["showAsMgDl"] as? Bool,
				  let min = dic["min"] as? Double,
				  let max = dic["max"] as? Double,
				  let urgentMin = dic["urgentMin"] as? Double,
				  let urgentMax = dic["urgentMax"] as? Double,
				  let suggestMin = dic["suggestMin"] as? Double,
				  let suggestMax = dic["suggestMax"] as? Double
			else {
				fatalError("Date formatter Error")
			}
			self.interval5Mins = interval5Mins
			self.showAsMgDl = showAsMgDl
			self.min = min
			self.max = max
			self.urgentMin = urgentMin
			self.urgentMax = urgentMax
			self.suggestMin = suggestMin
			self.suggestMax = suggestMax
		}
		
		func toDic() -> [String: Any] {
			return ["interval5Mins": interval5Mins,
					"showAsMgDl": showAsMgDl,
					"min": min,
					"max": max,
					"urgentMin": urgentMin,
					"urgentMax": urgentMax,
					"suggestMin": suggestMin,
					"suggestMax": suggestMax]
		}
	}
	
	struct DataTransformToPhone {
		var type: MessageValues
		
		init(type: MessageValues) {
			self.type = type
		}
		
		init(dic: [String: Any]) {
			guard let value = dic["type"] as? String,
				  let type = MessageValues(rawValue: value)
			else {
				fatalError("Date formatter Error")
			}
			self.type = type
		}
		
		func toDic() -> [String: Any] {
			return ["type": type.rawValue]
		}
	}
	
	struct DataTransformToWatch {
		var slope: BgSlope
		var latest: BgInfo?
		// 以下两个成组出现
		var recently: [BgInfo]?// 数据 从旧到新 排序
		var config: BgConfig?
		
		var lastDataDate: Date? {
			if let latest = latest {
				return latest.date
			}
			else if let recently = recently {
				return recently.last?.date
			}
			return nil
		}
		
		init(slope: BgSlope,
			 latest: BgInfo?,
			 recently: [BgInfo]?,
			 config: BgConfig?
		) {
			if recently == nil && latest == nil {
				fatalError("Date formatter Error")
			}
			if recently != nil && config == nil {
				fatalError("Date formatter Error")
			}
			self.slope = slope
			self.latest = latest
			self.recently = recently
			self.config = config
		}
		
		init(dic: [String: Any]) {
			if let slope = dic["slope"] as? Int {
				self.slope = BgSlope(rawValue: slope)!
			} else {
				fatalError("Date formatter Error")
			}
			if let latest = dic["latest"] as? [String : Any] {
				self.latest = BgInfo(dic: latest)
			}
			if let recently = dic["recently"] as? [[String : Any]] {
				self.recently = recently.map { BgInfo(dic: $0) }
			}
			if let config = dic["config"] as? [String : Any] {
				self.config = BgConfig(dic: config)
			}
			
			if recently == nil && latest == nil {
				fatalError("Date formatter Error")
			}
			if recently != nil && config == nil {
				fatalError("Date formatter Error")
			}
		}
		
		func toDic() -> [String: Any] {
			var result: [String: Any] = ["slope": slope.rawValue]
			if let config = config {
				result["config"] = config.toDic()
			} else {
				fatalError("Date formatter Error")
			}
			if let latest = latest {
				result["latest"] = latest.toDic()
			}
			if let recently = recently {
				result["recently"] = recently.map{ $0.toDic() }
			}
			return result
		}
	}
}
