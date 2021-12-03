//
//  ContentView.swift
//  WatchApp WatchKit Extension
//
//  Created by Liu Xudong on 2021/10/29.
//

import SwiftUI


struct ContentView: View {

	@EnvironmentObject var usefulData: UsefulData
	
	func getChartPointList(_ interval5Mins: Bool, from list: [Common.BgInfo]) -> [ChartPoint] {
		var result = [ChartPoint]()
		var lastItem: Common.BgInfo? = nil
		for bg in list {
			if interval5Mins == true
				&& (lastItem != nil)
				&& (abs(bg.date.timeIntervalSince(lastItem!.date)) < 4.5 * 60) {
				continue
			}
			lastItem = bg
			result.append(ChartPoint(x: Int(bg.date.timeIntervalSince1970),
								   y: bg.value))
		}
		return result
	}
	
	var body: some View {
		VStack(alignment: .leading) {
			if let config = usefulData.bgConfig {
				if let bgLatest = usefulData.bgLatest {
					HStack {
						let isDataValid = Date().timeIntervalSince(bgLatest.date) <= Constants.DataValidTimeInterval
						let trendStr = usefulData.slope.description
						let color = self.getColor(of: bgLatest.value, config: config)
						if config.showAsMgDl {
							Text(String(format: "%.0f", bgLatest.value))
								.font(.title)
								.foregroundColor(color)
                            
						} else {
							let number = Int(round(bgLatest.value * 10))
							let int = floor(Double(number / 10))
							let point = number - Int(int * 10)
                            
							HStack(alignment: .lastTextBaseline, spacing: 0) {
								Text(String(format: "%.0f.", int))
                                    .font(.title.bold())
									.foregroundColor(color)
                                
								Text(String(point))
									.font(.title2)
									.foregroundColor(color)
							}
							.overlay(
								Rectangle()
                                    .frame(maxWidth: isDataValid ? 0: 60,
                                           maxHeight: isDataValid ? 0: 1),
								alignment: .center
							)
						}
                        
						if isDataValid {
							// 有效期内
							Text(trendStr)
								.font(.title)
								.foregroundColor(color)
						}
					}
					Text(config.showAsMgDl ? "mg/dL" : "mmol/L")
						   .font(.footnote)
						   .foregroundColor(Color.secondary)
				}
                
                
				if usefulData.bgInfoList.count > 0 {
					WatchChartView(pointDigit: config.showAsMgDl ? 0 : 1,
                                   min: config.min,
                                   max: config.max,
                                   urgentMin: config.urgentMin,
                                   urgentMax: config.urgentMax,
                                   suggestMin: config.suggestMin,
                                   suggestMax: config.suggestMax,
								   values: getChartPointList(config.interval5Mins, from: usefulData.bgInfoList))
				}
			}
			Spacer(minLength: 10).frame(maxHeight: 10)
		}
	}
}

struct ContentView_Previews: PreviewProvider {
    
	static var previews: some View {
		let usefulData = UsefulData()
		let fake = PhoneCommunicator.fakeRecently()
		usefulData.bgLatest = Common.BgInfo(date: fake.last!.date, value: 5.6)
		usefulData.bgInfoList = fake
		usefulData.bgConfig = PhoneCommunicator.fakeConfig()
		usefulData.slope = Common.BgSlope.flat
        
		return ContentView().environmentObject(usefulData)
	}
}

extension ContentView {
    
	private func getColor(of value: Double, config: Common.BgConfig) -> Color {
		if value > config.urgentMax || value < config.urgentMin {
			return Constants.glucoseRed
            
		} else if value > config.suggestMax || value < config.suggestMin {
			return Constants.glucoseYellow
		}
		return Color.white
	}
}
