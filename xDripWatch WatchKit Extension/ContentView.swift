//
//  ContentView.swift
//  WatchApp WatchKit Extension
//
//  Created by Liu Xudong on 2021/10/29.
//

import SwiftUI


struct ContentView: View {

	@EnvironmentObject var usefulData: UsefulData
	
	var body: some View {
		ScrollView {
			VStack(alignment: .leading) {
				Button("Request") {
					PhoneCommunicator.shared.requestRecentlyChart()
				}
				if let config = usefulData.bgConfig {
					if let bgLatest = usefulData.bgLatest {
						let trendStr = String(format: "%.\(config.showAsMgDl ? 1 : 0)f %@",
										   bgLatest.value,
										   usefulData.slope.description)
						Text(trendStr)
							.font(.title)
							.strikethrough(bgLatest.date.timeIntervalSince(Date()) < -11 * 60)
					}
					Text(config.showAsMgDl ? "mg/dl" : "mmol/L")
						.font(.footnote)
					if usefulData.bgInfoList.count > 0 {
						let list = usefulData.bgInfoList.map {
							ChartPoint(x: Int($0.date.timeIntervalSince1970), y: $0.value)
						}
						WatchChartView(pointDigit: config.showAsMgDl ? 1 : 0,
								  min: config.min, max: config.max, urgentMin: config.urgentMin, urgentMax: config.urgentMax, suggestMin: config.suggestMin, suggestMax: config.suggestMax,
								  values: list)
					}
				}
			}
		}
	}
}

struct ContentView_Previews: PreviewProvider {
	static var previews: some View {
		ContentView()
	}
}
