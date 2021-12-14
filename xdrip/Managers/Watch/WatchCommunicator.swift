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
	
    private static let log = Log(type: WatchCommunicator.self)
    
    static let shared = WatchCommunicator()

    static func register() {
        _ = self.shared
    }
    
	private let session = WCSession.default
	
    private let watchManager = WatchManager.shared
	
	fileprivate override init() {
		super.init()

        session.delegate = self
		session.activate()
	}
}

extension WatchCommunicator: WCSessionDelegate {
    
	func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        WatchCommunicator.log.d("activationDidCompleteWith \(activationState.rawValue), error: \(error?.localizedDescription ?? "nil")")
	}
	
	func sessionDidBecomeInactive(_ session: WCSession) {
        WatchCommunicator.log.d("sessionDidBecomeInactive")
	}
	
	func sessionDidDeactivate(_ session: WCSession) {
        WatchCommunicator.log.d("sessionDidDeactivate")
	}
	
	// Sender
	func session(_ session: WCSession, didFinish userInfoTransfer: WCSessionUserInfoTransfer, error: Error?) {
        WatchCommunicator.log.d("session didFinish userInfoTransfer error: \(error?.localizedDescription ?? "nil")")
	}
	
	// Receiver
	func session(_ session: WCSession, didReceiveMessage message: [String : Any], replyHandler: @escaping ([String : Any]) -> Void) {
        WatchCommunicator.log.d("session didReceiveMessage message : \(message)")
        
		DispatchQueue.main.async { [unowned self] in
            let message = Common.DataTransformToPhone.init(dic: message)
            let type = message.type
            var data: Common.DataTransformToWatch?
            let config = WatchCommunicator.getConfig()
                
            if type == Common.MessageValues.latest {
                if let latestBg = self.watchManager.getLatest() {
                    let info = Common.BgInfo(date: latestBg.timeStamp,
                                             value: latestBg.calculatedValue.mgdlToMmol(mgdl: config.showAsMgDl))
                    let slope: Common.BgSlope = WatchCommunicator.convertSlope(of: latestBg.slopArrow)
                    data = Common.DataTransformToWatch.init(slope: slope,
                                                            latest: info,
                                                            recently: nil,
                                                            config: config)
                }
                
            } else if type == Common.MessageValues.recently {
                let list = self.watchManager.getRecently(6).sorted { a, b in
                    a.timeStamp < b.timeStamp
                }
                var recently = [Common.BgInfo]()
                for item in list {
                    let info = Common.BgInfo(date: item.timeStamp,
                                             value: item.calculatedValue.mgdlToMmol(mgdl: config.showAsMgDl))
                    recently.append(info)
                }
                let latest = list.last
                var slope = Common.BgSlope.flat
                if latest != nil {
                    slope = WatchCommunicator.convertSlope(of: latest!.slopArrow)
                }
                data = Common.DataTransformToWatch.init(slope: slope,
                                                        latest: recently.last,
                                                        recently: recently,
                                                        config: config)
            }
            replyHandler(data?.toDic() ?? [:])
		}
	}
}

extension WatchCommunicator {
    
	static func getConfig() -> Common.BgConfig {
		let showAsMgDl = UserDefaults.standard.bloodGlucoseUnitIsMgDl
		return Common.BgConfig(
			interval5Mins: UserDefaults.standard.chartDots5MinsApart,
			showAsMgDl: showAsMgDl,
			min: (40).mgdlToMmol(mgdl: showAsMgDl),
			max: UserDefaults.standard.chartHeight.mgdlToMmol(mgdl: showAsMgDl),
			urgentMin: UserDefaults.standard.urgentLowMarkValue.mgdlToMmol(mgdl: showAsMgDl),
			urgentMax: UserDefaults.standard.urgentHighMarkValue.mgdlToMmol(mgdl: showAsMgDl),
			suggestMin: UserDefaults.standard.lowMarkValue.mgdlToMmol(mgdl: showAsMgDl),
			suggestMax: UserDefaults.standard.highMarkValue.mgdlToMmol(mgdl: showAsMgDl))
	}
	
	static func convertSlope(of arrow: BgReading.SlopeArrow) -> Common.BgSlope {
		switch arrow {
		case .doubleUp:
			return .upDouble
		case .singleUp:
			return .up
		case .fortyFiveUp:
			return .upHalf
		case .flat:
			return .flat
		case .fortyFiveDown:
			return .downHalf
		case .singleDown:
			return .down
		case .doubleDown:
			return .downDouble
		}
	}
	
	static func fakeConfig() -> Common.BgConfig {
		Common.BgConfig(interval5Mins: true, showAsMgDl: true, min: 2.2, max: 16.6, urgentMin: 3.9, urgentMax: 10, suggestMin: 4.5, suggestMax: 7.8)
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
