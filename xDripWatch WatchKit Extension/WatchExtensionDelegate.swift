//
//  ExtensionDelegate.swift
//  WatchApp WatchKit Extension
//
//  Created by Liu Xudong on 2021/11/2.
//

import Foundation
import SwiftUI
import WatchKit
import ClockKit

class WatchExtensionDelegate: NSObject, ObservableObject, WKExtensionDelegate {

	var runtimeSession: WKExtendedRuntimeSession?
	
	func applicationWillEnterForeground() {
	}
	
	func applicationWillResignActive() {
	}
	func handle(_ backgroundTasks: Set<WKRefreshBackgroundTask>) {
		print(Date(), #function, backgroundTasks.count)
		for task in backgroundTasks {
			
			ComplicationController.reload()
			WatchExtensionDelegate.fireBackgroundTasks()
			
			task.expirationHandler = {
				WatchExtensionDelegate.fireBackgroundTasks()
				task.setTaskCompletedWithSnapshot(false)
			}
			task.setTaskCompletedWithSnapshot(false)
		}
	}
	
	static func fireBackgroundTasks() {
		let info: NSDictionary = ["data": Constants.RefreshComplicationBackgroundTaskName]
		WKExtension.shared().scheduleBackgroundRefresh(withPreferredDate: .now + Constants.UpdateTimeInterval, userInfo: info) { error in
			print("scheduleBackgroundRefresh error:", error?.localizedDescription ?? "nil")
		}
	}
}

extension WatchExtensionDelegate: WKExtendedRuntimeSessionDelegate {
	func extendedRuntimeSessionDidStart(_ extendedRuntimeSession: WKExtendedRuntimeSession) {
	}
	
	func extendedRuntimeSessionWillExpire(_ extendedRuntimeSession: WKExtendedRuntimeSession) {
	}
	
	func extendedRuntimeSession(_ extendedRuntimeSession: WKExtendedRuntimeSession, didInvalidateWith reason: WKExtendedRuntimeSessionInvalidationReason, error: Error?) {
	}
}
