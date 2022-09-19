//
//  Constants.swift
//  WatchApp WatchKit Extension
//
//  Created by Liu Xudong on 2021/11/2.
//

import Foundation
import SwiftUI

class Constants {
	static let DisplayName = "zDrip"
	static let RefreshComplicationBackgroundTaskName: String = "RefreshComplicationBackgroundTaskName"
	
	static let UpdateTimeInterval = 60.0 // Senconds
	#if DEBUG
	static let DataValidTimeInterval = 11.0 // Senconds
	#else
	static let DataValidTimeInterval = 11 * 60.0 // Senconds
	#endif
	static let glucoseRed: Color = Color.init(Common.Constants.glucoseRed)
	static let glucoseYellow: Color = Color.init(Common.Constants.glucoseYellow)
	static let glucoseGreen: Color = Color.init(Common.Constants.glucoseGreen)
}
