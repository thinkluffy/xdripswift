//
//  EasyTracker.swift
//  Paintist
//
//  Created by Yuanbin Cai on 2020/5/3.
//  Copyright © 2020 thinkyeah. All rights reserved.
//

import FirebaseAnalytics
import FirebaseCrashlytics

public class EasyTracker {
    
    public static func logEvent(_ eventName: String, parameters: [String: Any]? = nil) {
        Analytics.logEvent(eventName, parameters: parameters)
    }
    
    public static func value(_ value: Int) -> [String: Int] {
        return [AnalyticsParameterValue: value]
    }
	
	public static func value(_ value: String) -> [String: String] {
		return [AnalyticsParameterValue: value]
	}
    
    public static func itemId(_ value: String) -> [String: String] {
        return [AnalyticsParameterItemID: value]
    }
    
	public static func record(_ error: Error) {
		Crashlytics.crashlytics().record(error: error)
	}
	
    // MARK: - commen events
    
    public static func logAppOpen() {
        Analytics.logEvent(AnalyticsEventAppOpen, parameters: nil)
    }
    
    public static func logLevelStart(levelName: String) {
        Analytics.logEvent(AnalyticsEventLevelStart, parameters: [AnalyticsParameterLevelName: levelName])
    }
    
    public static func logLevelEnd(levelName: String, success: Bool) {
        Analytics.logEvent(AnalyticsEventLevelEnd, parameters: [
            AnalyticsParameterLevelName: levelName,
            AnalyticsParameterSuccess: success
        ])
    }
}
