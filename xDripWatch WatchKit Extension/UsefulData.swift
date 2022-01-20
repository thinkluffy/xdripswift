//
//  UsefulData.swift
//  WatchApp WatchKit Extension
//
//  Created by Liu Xudong on 2021/10/29.
//

import Foundation
import SwiftUI

class ObjectWithDate {
	var date: Date
	var value: Any
	
	init(date: Date = Date(), value: Any) {
		self.date = date
		self.value = value
	}
}

enum LatestDataState {
	case initial
	case fetching
	case success
	case failed(error: Error)
}

class UsefulData: ObservableObject {
	@Published var bgLatest: Common.BgInfo?
	@Published var bgInfoList: [Common.BgInfo] = []
	@Published var bgConfig: Common.BgConfig?
	@Published var slope: Common.BgSlope?
	@Published var isLoadingLatest: Bool = false
}
