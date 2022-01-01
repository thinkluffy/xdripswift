//
//  EasyTracker.swift
//  Paintist
//
//  Created by Yuanbin Cai on 2020/5/3.
//  Copyright © 2020 thinkyeah. All rights reserved.
//

import FirebaseAnalytics
import FirebaseCrashlytics
import AppCenterAnalytics

public class EasyTracker {
    
    public static func logEvent(_ eventName: String, parameters: [String: String]? = nil) {
        FirebaseAnalytics.Analytics.logEvent(eventName, parameters: parameters)
        AppCenterAnalytics.Analytics.trackEvent(eventName, withProperties: parameters)
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
}
