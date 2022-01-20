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
			if interval5Mins && lastItem != nil &&
                abs(bg.date.timeIntervalSince(lastItem!.date)) <= 4.5 * 60 {
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
				HStack {
					if let bgLatest = usefulData.bgLatest {
						let isDataValid = Date().timeIntervalSince(bgLatest.date) <= Constants.DataValidTimeInterval
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
                        
						if isDataValid, let slope = usefulData.slope {
							// 有效期内
							Text(slope.description)
								.font(.title)
								.foregroundColor(color)
						}
					} else {
						Text("---")
					}
					Text(config.showAsMgDl ? "mg/dL" : "mmol/L")
						   .font(.footnote)
						   .foregroundColor(Color.secondary)
				}
                
				if usefulData.bgInfoList.count > 0 {
					WatchChartView(pointDigit: config.showAsMgDl ? 0 : 1,
                                   chartLow: config.chartLow,
                                   chartHigh: config.chartHigh,
                                   urgentLow: config.urgentLow,
                                   urgentHigh: config.urgentHigh,
                                   suggestLow: config.suggestLow,
                                   suggestHigh: config.suggestHigh,
								   values: getChartPointList(config.interval5Mins, from: usefulData.bgInfoList))
				} else {
					Text("No Data")
				}
			} else {
				if usefulData.isLoadingLatest {
					Text("Loading ...")
				} else {
					Text("Invalid Data")
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
		if value > config.urgentHigh || value < config.urgentLow {
			return Constants.glucoseRed
            
		} else if value > config.suggestHigh || value < config.suggestLow {
			return Constants.glucoseYellow
		}
		return Color.white
	}
}
