//
//  ChartView.swift
//  WatchApp WatchKit Extension
//
//  Created by Liu Xudong on 2021/11/9.
//

import SwiftUI

struct ChartPoint {
	var x: Int // TimeInterval since 1970
	var y: Double // value
	
	init(x: Int,
		 y: Double) {
		self.x = x
		self.y = y
	}
}

enum TimeRange {
	case hour1
	case hour3
	case hour6
	
	var shortTitle: String {
		switch self {
		case .hour1:
			return "1 HR"
		case .hour3:
			return "3 HR"
		case .hour6:
			return "6 HR"
		}
	}
	var chartPointRadius: CGFloat {
		switch self {
		case .hour1:
			return 6
		case .hour3:
			return 3
		case .hour6:
			return 2
		}
	}
}

struct WatchChartView: View {
	
	private let RightLabelWidth: CGFloat = 25
	
	private var pointDigit:Int
	private var minY: Double!
	private var maxY: Double!
	private var urgentMin: Double!
	private var urgentMax: Double!
	private var suggestMin: Double!
	private var suggestMax: Double!
	private var originValues: [ChartPoint]!
	
	private var last1hour = [ChartPoint]()
	private var last3hour = [ChartPoint]()
	private var last6hour = [ChartPoint]()
	
	@State private var timeRange: TimeRange
	
	init(pointDigit: Int = 1,
		 min: Double, max: Double,
		 urgentMin: Double, urgentMax: Double,
		 suggestMin: Double, suggestMax: Double,
		 values: [ChartPoint]) {
		self.pointDigit = pointDigit
		self.minY = min
		self.maxY = max
		self.urgentMin = urgentMin
		self.urgentMax = urgentMax
		self.suggestMin = suggestMin
		self.suggestMax = suggestMax
		self.originValues = values
		
		let oneHour = 60 * 60
		for value in originValues {
			switch Int(Date().timeIntervalSince1970) - value.x {
			case 0...oneHour:
				last1hour.append(value)
			case oneHour...oneHour*3:
				last3hour.append(value)
			case oneHour*3...oneHour*6:
				last6hour.append(value)
			default:
				break
				
			}
		}
		
		self.timeRange = .hour1
	}
	
    var body: some View {
		var values = [ChartPoint]()
		switch timeRange {
		case .hour1:
			values =  last1hour
		case .hour3:
			values =  last3hour + last1hour
		case .hour6:
			values =  last6hour + last3hour + last1hour
		}
		return ZStack {
			// 说明性文字
			GeometryReader { reader in
			   let font = Font.system(size: 12)
			   let textWidth: CGFloat = RightLabelWidth
			   let textHeight: CGFloat = 20
			   let suggestMinY = reader.size.height * CGFloat((self.maxY - self.suggestMin) / (self.maxY - self.minY))// + textHeight/2
			   let suggestMaxY = reader.size.height * CGFloat((self.maxY - self.suggestMax) / (self.maxY - self.minY))// - textHeight/2
			   Text(timeRange.shortTitle)
				   .font(font)
				   .foregroundColor(Color.secondary)
				   .frame(width: 40, height: textHeight)
				   .position(x: 20, y: textHeight/2) // 顺序不能变
			   Text(String(format: "%.\(self.pointDigit)f", self.suggestMax))
				   .font(font)
				   .foregroundColor(Color.secondary)
				   .frame(width: textWidth, height: textHeight)
				   .position(x: reader.size.width - textWidth/2, y: suggestMaxY)
			   Text(String(format: "%.\(self.pointDigit)f", self.suggestMin))
				   .font(font)
				   .foregroundColor(Color.secondary)
				   .frame(width: textWidth, height: textHeight)
				   .position(x: reader.size.width - textWidth/2, y: suggestMinY)
		   }
		   // 绘制两支横向辅导线,一支竖线辅导线
		   GeometryReader { reader in
			   let minY = reader.size.height * CGFloat((self.maxY - self.suggestMin) / (self.maxY - self.minY))
			   let maxY = reader.size.height * CGFloat((self.maxY - self.suggestMax) / (self.maxY - self.minY))
			   let minX: CGFloat = 0
			   let maxX = reader.size.width
			   let verticalMaxX = maxX - RightLabelWidth
			   Group {
				   Path { p in
					   // 低线
					   p.move(to: CGPoint(x: minX, y: minY))
					   p.addLine(to: CGPoint(x: verticalMaxX, y: minY))
					   // 高线
					   p.move(to: CGPoint(x: minX, y: maxY))
					   p.addLine(to: CGPoint(x: verticalMaxX, y: maxY))
				   }.stroke(Color.secondary, style: StrokeStyle(dash: [2,4]))
				   Path { p in
					   // 竖线
					   p.move(to: CGPoint(x: verticalMaxX, y: 0))
					   p.addLine(to: CGPoint(x: verticalMaxX, y: reader.size.height))
				   }.stroke(Color(white: 1, opacity: 0.5),
							lineWidth: 0.5)
			   }
		   }
		   // 曲线
		   GeometryReader { reader in
			   if values.count == 1 {
				   let value = values.first!
				   let radius: CGFloat = 10
				   Path { p in
					   let height = reader.size.height * CGFloat((self.maxY - value.y) / (self.maxY - self.minY))
					   p.addEllipse(in: CGRect(x: reader.size.width/2 - radius/2,
										  y: height - radius/2,
										  width: radius,
										  height: radius))
				   }.fill(self.getColor(of: value.y))
			   }
			   else if values.count > 1 {
				   // https://stackoverflow.com/questions/57244713/get-index-in-foreach-in-swiftui
				   ForEach(values.indices, id: \.self) { i in
					   let first: ChartPoint = values.first!
					   let maxTimeInterval: CGFloat = CGFloat(Int(Date().timeIntervalSince1970) - first.x)
					   let pathWidth = reader.size.width - RightLabelWidth
//					   var radius: CGFloat = pathWidth * 5 * 60 / maxTimeInterval
					   let radius: CGFloat = timeRange.chartPointRadius
					   let value = values[i]
					   
					   if value.y <= self.maxY && value.y >= self.minY {
						   let x = (pathWidth - radius) * CGFloat(value.x - first.x) / maxTimeInterval
						   let height = reader.size.height * CGFloat((self.maxY - value.y) / (self.maxY - self.minY))
						   Path { p in
							   p.addEllipse(in:
											   CGRect(x: x,
													  y: height - radius/2,
													  width: radius,
													  height: radius))
						   }.fill(self.getColor(of: value.y))
					   }
				   }
			   }
		   }
		}
		.background(Color.init(red: 19/255, green: 24/255, blue: 51/255))
		.cornerRadius(10)
		.onTapGesture {
		   switch timeRange {
		   case .hour1:
			   timeRange = .hour3
		   case .hour3:
			   timeRange = .hour6
		   case .hour6:
			   timeRange = .hour1
		   }
		}
	}
}

extension WatchChartView {
	private func getColor(of value: Double) -> Color {
		if value > self.urgentMax || value < self.urgentMin {
			return Constants.glucoseRed
		}
		else if value > self.suggestMax || value < self.suggestMin {
			return Constants.glucoseYellow
		}
		return Constants.glucoseGreen
	}
}

struct ChartView_Previews: PreviewProvider {
    static var previews: some View {
		WatchChartView(pointDigit: 0, min: 2.2 * 18, max: 16.6*18, urgentMin: 3.9*18, urgentMax: 10*18, suggestMin: 4.5*18, suggestMax: 7.8*18, values: WatchChartView.fakeValues().map{ ChartPoint(x: $0.x, y: $0.y * 18)})
    }
}

extension WatchChartView {
	
	static func fakeValues() -> [ChartPoint] {
		var result = [ChartPoint]()
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
			result.append(ChartPoint(x: Int(i), y:last))
		}
		return result
	}
}
