//
//  PhoneCommunicator.swift
//  WatchApp WatchKit Extension
//
//  Created by Liu Xudong on 2021/10/29.
//

import Foundation
import WatchConnectivity
import SwiftUI
import CryptoKit

extension WCSession {
	
	var isReady: Bool {
		guard self.activationState == .activated,
			  self.isReachable// A Boolean value indicating whether the counterpart app is available for live messaging.
		else {
			print("isReady", self.activationState == .activated, self.isReachable)
			return false
		}
		return true
	}
	
}

class PhoneCommunicator: NSObject {
	
	static func register() {
		_ = self.shared
	}

	static let shared = PhoneCommunicator()
	
	private let session = WCSession.default
	
	private var requestTimer: Timer?

	var usefulData = UsefulData()
	
	var previousOne: ObjectWithDate?
	
	fileprivate override init() {
		super.init()
		print("init PhoneCommunicator")
		session.delegate = self
		session.activate()
	}
	
	func startRequestChart() {
		guard self.session.activationState == .activated else { return }
		requestTimer?.invalidate()
		requestTimer = Timer(timeInterval: Constants.UpdateTimeInterval, repeats: true, block: { [weak self] timer in
			self?.requestRecentlyChart()
		})
		RunLoop.main.add(requestTimer!, forMode: .common)
		requestTimer?.fire()
	}
	
	func stopRequestChart() {
		requestTimer?.invalidate()
		requestTimer = nil
	}
	
	func requestLatest(completion: @escaping ((Date, String)?) -> Void) {
//		completion((Date(timeIntervalSinceNow: -12 * 60), "5.6>"))
//		return
		guard session.isReady else {
			DispatchQueue.main.async {
				if let lastest = self.previousOne {
					completion((lastest.date, lastest.value as! String))
				} else {
					completion(nil)
				}
			}
			return
		}
		let message = Common.DataTransformToPhone.init(type: .latest).toDic()
		print("will requestLatest")
		session.sendMessage(message) { reply in
			DispatchQueue.main.async {
				if reply.keys.count == 0 {
					if let lastest = self.previousOne {
						completion((lastest.date, lastest.value as! String))
					} else {
						completion(nil)
					}
					return
				}
				let data = Common.DataTransformToWatch.init(dic: reply)
				if let latest = data.latest
				{
					print("requestLatest reply: \(reply)")
					let showAsMgDl = data.config?.showAsMgDl ?? true
					let slope = data.slope
					let trendStr = String(format: "%.\(showAsMgDl ? 0 : 1)f %@",
										  latest.value,
										  slope.description)
					self.previousOne = ObjectWithDate(date: latest.date, value: trendStr)
					completion((latest.date, trendStr))
				} else {
					print("requestLatest formatter error reply: \(reply)")
					completion(nil)
				}
			}
		} errorHandler: { error in
			DispatchQueue.main.async {
				print("requestLatest failed: \(error.localizedDescription)")
				if let lastest = self.previousOne {
					completion((lastest.date, lastest.value as! String))
				} else {
					completion(nil)
				}
			}
		}
	}
	
	func requestRecentlyChart() {
//		DispatchQueue.main.async {
//			let fake = PhoneCommunicator.fakeRecently()
//			self.usefulData.bgLatest = fake.last
//			self.usefulData.bgInfoList = fake
//			self.usefulData.bgConfig = PhoneCommunicator.fakeConfig()
//			self.usefulData.slope = Common.BgSlope.flat
//		}
//		return
		guard session.isReady else {
			return
		}
		let message = Common.DataTransformToPhone.init(type: .recently).toDic()
		print(message)
		session.sendMessage(message) { [unowned self] reply in
			print("requestLatest reply: \(reply)")
			if reply.keys.count == 0 {
				self.requestTimer?.fire()
				return
			}
			let data = Common.DataTransformToWatch.init(dic: reply)
			DispatchQueue.main.async {
				self.usefulData.bgLatest = data.latest
				self.usefulData.bgInfoList = data.recently ?? []
				self.usefulData.bgConfig = data.config
				self.usefulData.slope = data.slope
				if let latest = data.latest {
					self.previousOne = ObjectWithDate(date: latest.date, value: latest.value)
				}
			}
		} errorHandler: { error in
			print("requestRecentlyChart failed: \(error.localizedDescription)")
		}
	}
}


extension PhoneCommunicator: WCSessionDelegate {
	func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
		print("session activationDidCompleteWith \(activationState.rawValue), error: \(error?.localizedDescription ?? "nil")")
		if activationState == .activated {
			PhoneCommunicator.shared.startRequestChart()
		} else {
			PhoneCommunicator.shared.stopRequestChart()
		}
	}
	
	// Receiver transferComplication
	func session(_ session: WCSession, didReceiveUserInfo userInfo: [String : Any] = [:]) {
		print("session didReceiveUserInfo: \(userInfo)")
	}
	
	// Receiver No called expected, redundancy with send message reply
	func session(_ session: WCSession, didReceiveMessage message: [String : Any]) {
		print("session didReceiveMessage: \(message)")
	}
}
extension PhoneCommunicator {
	static func fakeConfig() -> Common.BgConfig {
		Common.BgConfig(showAsMgDl: false, min: 2.2, max: 16.6, urgentMin: 3.9, urgentMax: 10, suggestMin: 4.5, suggestMax: 7.8)
	}
	
	static func fakeRecently() -> [Common.BgInfo] {
		var result = [Common.BgInfo]()
		var last: Double = 6.7
		let now = Date()
		// 六小时前 - 现在
		let start = Int(now.addingTimeInterval(-6*60*60).timeIntervalSince1970)
		let end = Int(now.addingTimeInterval(-1*60*60).timeIntervalSince1970)//
		for i in stride(from: start, to: end + 1, by: 5*60) {
			last = last + Double.random(in: -0.6...0.6)
			last = min(16.6, max(2.2, last))
			if Int.random(in: 0..<100) > 90{
				// 模拟90%的几率没数据
				continue
			}
			let info = Common.BgInfo(date: Date(timeIntervalSince1970: TimeInterval(i)), value: last)
			result.append(info)
		}
		return result
	}
}
