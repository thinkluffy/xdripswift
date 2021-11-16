//
//  WatchCommunicator.swift
//  WatchHostApp
//
//  Created by Liu Xudong on 2021/10/29.
//

import Foundation
import WatchConnectivity

extension WCSession {
	
	var isReady: Bool {
		guard WCSession.isSupported(),// Returns a Boolean value indicating whether the current iOS device is able to use a session object.
			  self.isPaired, // A Boolean indicating whether the current iPhone has a paired Apple Watch.
			  self.activationState == .activated,
			  self.isWatchAppInstalled // A Boolean value indicating whether the currently paired and active Apple Watch has installed the app.
				// sendMessage neccessnary， tranfer complications not
//				self.isReachable// A Boolean value indicating whether the counterpart app is available for live messaging.
		else {
			print(WCSession.isSupported(), self.isPaired, self.activationState == .activated, self.isWatchAppInstalled, self.isReachable)
			return false
		}
		return true
	}
	
}

class WatchCommunicator: NSObject {
	
	static func register() {
		_ = self.shared
	}
	
	static let shared = WatchCommunicator()
	
	private let session = WCSession.default
	
	private var coreDataManager: CoreDataManager?
	private var dataManager: WatchManager?
	
	fileprivate override init() {
		super.init()
		print("init WatchCommunicator")
		session.delegate = self
		session.activate()
		coreDataManager = CoreDataManager(modelName: ConstantsCoreData.modelName, completion: {
			self.dataManager = WatchManager(coreDataManager: self.coreDataManager!)
		})
	}
}


extension WatchCommunicator: WCSessionDelegate {
	func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
		print("activationDidCompleteWith \(activationState.rawValue), error: \(error?.localizedDescription ?? "nil")")
	}
	
	func sessionDidBecomeInactive(_ session: WCSession) {
		print("sessionDidBecomeInactive")
	}
	
	func sessionDidDeactivate(_ session: WCSession) {
		print("sessionDidDeactivate")
	}
	
	// Sender
	func session(_ session: WCSession, didFinish userInfoTransfer: WCSessionUserInfoTransfer, error: Error?) {
		print("session didFinish userInfoTransfer error: \(error?.localizedDescription ?? "nil")")
	}
	
	// Receiver
	func session(_ session: WCSession, didReceiveMessage message: [String : Any], replyHandler: @escaping ([String : Any]) -> Void) {
		print("session didReceiveMessage message : \(message)")
		guard let dataManager = self.dataManager else {
			replyHandler([:])
			return
		}
		DispatchQueue.main.async {
			
		let message = Common.DataTransformToPhone.init(dic: message)
		let type = message.type
		var data: Common.DataTransformToWatch?
		if type == Common.MessageValues.latest {
			if let latestBg = dataManager.getLatest() {
				let c = latestBg.value(forKey: "calibration")
				print(c)
				if let calibration = latestBg.calibration {
					let info = Common.BgInfo(date: calibration.timeStamp, value: calibration.bg)
					let slope: Common.BgSlope = latestBg.slopArrow == .singleUp ? .up : .down
					data = Common.DataTransformToWatch.init(slope: slope,
															latest: info,
															recently: nil,
															config: nil)
				}
			}
		}
		else if type == Common.MessageValues.recently {
			let list = WatchCommunicator.fakeRecently()
			data = Common.DataTransformToWatch.init(slope: .up,
													latest: list.last,
													recently: list,
													config: WatchCommunicator.fakeConfig())
		}
		replyHandler(data?.toDic() ?? [:])
		}
	}
}

extension WatchCommunicator {
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
		for i in stride(from: start, to: end, by: 5*60) {
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
