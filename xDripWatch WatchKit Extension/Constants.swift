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
	static let DataValidTimeInterval = 11 * 60.0 // Senconds
	
	static let glucoseRed = Color(red: 234/255, green: 45/255, blue: 100/255, opacity: 1)
	static let glucoseYellow = Color(red: 233/255, green: 127/255, blue: 57/255, opacity: 1)
	static let glucoseGreen = Color(red: 72/255, green: 235/255, blue: 56/255, opacity: 1)
}
