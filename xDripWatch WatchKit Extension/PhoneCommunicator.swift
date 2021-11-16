//
//  PhoneCommunicator.swift
//  WatchApp WatchKit Extension
//
//  Created by Liu Xudong on 2021/10/29.
//

import Foundation
import WatchConnectivity
import SwiftUI

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
	
	deinit {
		print("PhoneCommunicator deinit")
	}
	static let shared = PhoneCommunicator()
	
	private let session = WCSession.default
	
	private var requestTimer: Timer?

	var usefulData = UsefulData()
	
	var lastest: ObjectWithDate?
	
	fileprivate override init() {
		super.init()
		print("init PhoneCommunicator")
		session.delegate = self
		session.activate()
	}
	
	func startRequestChart() {
		guard self.session.activationState == .activated else { return }
		requestTimer?.invalidate()
		requestTimer = Timer.scheduledTimer(withTimeInterval: Constants.UpdateTimeInterval, repeats: true, block: { [weak self] timer in
			self?.requestRecentlyChart()
		})
		RunLoop.main.add(requestTimer!, forMode: .common)
		requestTimer?.fire()
	}
	
	func stopRequestChart() {
		requestTimer?.invalidate()
		requestTimer = nil
	}
	
	func requestLatest(completion: @escaping ((String?) -> Void)) {
		
		if let old = lastest,
			Date().timeIntervalSince(old.date) < Constants.DataValidTimeInterval,
		   let value = old.value as? String
		{
			DispatchQueue.main.async {
				print("requestLatest reuse old value")
				completion(value)
			}
			return
		}
		guard session.isReady else {
			DispatchQueue.main.async {
				print("requestLatest false")
				completion(nil)
			}
			return
		}
		let message = Common.DataTransformToPhone.init(type: .latest).toDic()
		print("requestLatest will sendMessage")
		session.sendMessage(message) { reply in
			DispatchQueue.main.async {
				if reply.keys.count == 0 {
					completion(nil)
					return
				}
				let data = Common.DataTransformToWatch.init(dic: reply)
				if let value = data.latest?.value
				{
					self.lastest = ObjectWithDate(date: Date(), value: value)
					print("requestLatest reply: \(reply)")
					completion("\(value)")
				} else {
					// TODO
					print("requestLatest  formatter error reply: \(reply)")
					completion(nil)
				}
			}
		} errorHandler: { error in
			// TODO
			DispatchQueue.main.async {
				print("requestLatest failed: \(error.localizedDescription)")
				completion(nil)
			}
		}
	}
	
	func requestRecentlyChart() {
//		DispatchQueue.main.async {
//			self.usefulData.bgInfoList = PhoneCommunicator.fakeRecently()
//			self.usefulData.bgLatest = self.usefulData.bgInfoList.last
//			self.usefulData.bgConfig = PhoneCommunicator.fakeConfig()
//			self.usefulData.slope = .up
//		}
//		return
		guard session.isReady else {
			print("requestRecentlyChart false")
			return
		}
		let message = Common.DataTransformToPhone.init(type: .recently).toDic()
		print(message)
		session.sendMessage(message) { reply in
			let data = Common.DataTransformToWatch.init(dic: reply)
			print(reply)
			DispatchQueue.main.async {
				self.usefulData.bgLatest = data.latest
				self.usefulData.bgInfoList = data.recently ?? []
				self.usefulData.bgConfig = data.config
				self.usefulData.slope = data.slope
//				if let latest = data.latest {
//					self.lastest = ObjectWithDate(date: latest.date, value: latest.value)
//					ComplicationController.reload()
//				}
			}
		} errorHandler: { error in
			// TODO
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
		Common.BgConfig(showAsMgDl: true, min: 2.2, max: 16.6, urgentMin: 3.9, urgentMax: 10, suggestMin: 4.5, suggestMax: 7.8)
	}
	
	static func fakeRecently() -> [Common.BgInfo] {
		var result = [Common.BgInfo]()
		var last: Double = 6.7
		let now = Date()
		// 六小时前 - 现在
		let start = Int(now.addingTimeInterval(-6*60*60).timeIntervalSince1970)
		let end = Int(now.timeIntervalSince1970)
		for i in stride(from: start, to: end + 1, by: 5*60) {
			last = last + Double.random(in: -0.4...0.4)
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
