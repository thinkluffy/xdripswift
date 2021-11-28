//
//  GlucoseChart.swift
//  xdrip
//
//  Created by Yuanbin Cai on 2021/11/27.
//  Copyright © 2021 Johan Degraeve. All rights reserved.
//

import UIKit
import Charts

class GlucoseChart: UIView {

    private static let log = Log(type: GlucoseChart.self)
    
    private lazy var chartView = ScatterChartView()
    
    private lazy var urgentHighLine = ChartLimitLine()
    private lazy var highLine = ChartLimitLine()
    private lazy var lowLine = ChartLimitLine()
    private lazy var rangeTopLine = ChartLimitLine()
    private lazy var rangeBottomLine = ChartLimitLine()

    var chartHours = ChartHours.H3 {
        didSet {
            applyChartHours()
        }
    }
    
    private var chartCurrentDataSet: ScatterChartDataSet?

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        initialize()
    }
    
    init() {
        super.init(frame: .zero)
        initialize()
    }
    
    private func initialize() {
        addSubview(chartView)
        
        chartView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        
        setupChart()
    }
    
    private func setupChart() {
//        chartView.delegate = self

        chartView.dragEnabled = false
        chartView.chartDescription?.enabled = false
        chartView.setScaleEnabled(false)
        chartView.pinchZoomEnabled = false
        chartView.legend.enabled = false
        
        let xAxis = chartView.xAxis
        xAxis.labelFont = .systemFont(ofSize: 12)
        xAxis.labelTextColor = .white
        xAxis.valueFormatter = HourAxisValueFormatter()
        xAxis.labelPosition = .bottom
        xAxis.gridColor = ConstantsUI.mainBackgroundColor
        xAxis.gridLineWidth = 2
        xAxis.axisLineColor = ConstantsUI.mainBackgroundColor
        xAxis.axisLineWidth = 2
        if chartHours == ChartHours.H24 ||
            chartHours == ChartHours.H12 {
            xAxis.granularity = Date.hourInSeconds * 3 // 2 hours do not work, why?

        } else {
            xAxis.granularity = Date.hourInSeconds
        }
        xAxis.labelCount = 13 // make the x labels step by 1 hour, do not know why
        
        chartView.leftAxis.enabled = false

        // leave space for limit labels outside viewport
        chartView.setExtraOffsets(left: 0, top: 0, right: 30, bottom: 0)
        
        let yAxis = chartView.rightAxis
        yAxis.drawGridLinesEnabled = false
        yAxis.drawLabelsEnabled = false
        yAxis.axisLineColor = ConstantsUI.mainBackgroundColor
        yAxis.axisLineWidth = 2
        
        setupLimitLines()
    }

    private func setupLimitLines() {
        urgentHighLine.lineWidth = 1
        urgentHighLine.lineDashLengths = [5, 5]
        urgentHighLine.labelPosition = .right
        urgentHighLine.valueFont = .systemFont(ofSize: 12)
        urgentHighLine.lineColor = .gray
        urgentHighLine.valueTextColor = .white
        
        highLine.lineWidth = 1
        highLine.lineDashLengths = [5, 5]
        highLine.labelPosition = .right
        highLine.valueFont = .boldSystemFont(ofSize: 14)
        highLine.lineColor = .gray
        highLine.valueTextColor = .white
        
        lowLine.lineWidth = 1
        lowLine.lineDashLengths = [5, 5]
        lowLine.labelPosition = .right
        lowLine.valueFont = .boldSystemFont(ofSize: 14)
        lowLine.lineColor = .gray
        lowLine.valueTextColor = .white
        
        rangeTopLine.lineWidth = 2
        rangeTopLine.lineColor = ConstantsUI.mainBackgroundColor
        rangeTopLine.labelPosition = .right
        rangeTopLine.valueFont = .systemFont(ofSize: 12)
        rangeTopLine.valueTextColor = .gray
        
        rangeBottomLine.lineWidth = 0
        rangeBottomLine.lineColor = ConstantsUI.mainBackgroundColor
        rangeBottomLine.labelPosition = .right
        rangeBottomLine.valueFont = .systemFont(ofSize: 12)
        rangeBottomLine.valueTextColor = .gray
        
        let yAxis = chartView.rightAxis
        
        yAxis.removeAllLimitLines()
        yAxis.addLimitLine(urgentHighLine)
        yAxis.addLimitLine(highLine)
        yAxis.addLimitLine(lowLine)
        yAxis.addLimitLine(rangeTopLine)
        yAxis.addLimitLine(rangeBottomLine)
        
        yAxis.drawLimitLinesBehindDataEnabled = true
    }
    
    private func applySettings() {
        let showAsMg = UserDefaults.standard.bloodGlucoseUnitIsMgDl

        let yAxis = chartView.rightAxis
        yAxis.axisMaximum = showAsMg ? 300 : 16.6
        yAxis.axisMinimum = showAsMg ? 40 : 2.2
        
        let urgentHigh = UserDefaults.standard.urgentHighMarkValue.mgdlToMmol(mgdl: showAsMg)
        let high = UserDefaults.standard.highMarkValue.mgdlToMmol(mgdl: showAsMg)
        let low = UserDefaults.standard.lowMarkValue.mgdlToMmol(mgdl: showAsMg)
        
        urgentHighLine.limit = urgentHigh
        urgentHighLine.label = urgentHigh.bgValuetoString(mgdl: showAsMg)
        
        highLine.limit = high
        highLine.label = high.bgValuetoString(mgdl: showAsMg)
        
        lowLine.limit = low
        lowLine.label = low.bgValuetoString(mgdl: showAsMg)
        
        rangeTopLine.limit = yAxis.axisMaximum
        rangeTopLine.label = yAxis.axisMaximum.bgValuetoString(mgdl: showAsMg)
        
        rangeBottomLine.limit = yAxis.axisMinimum
        rangeBottomLine.label = yAxis.axisMinimum.bgValuetoString(mgdl: showAsMg)
    }
    
    func show(readings: [BgReading]?, from fromDate: Date, to toDate: Date) {
        applySettings()

        guard let readings = readings else {
            GlucoseChart.log.e("reading is nil, nothing to show")
            chartView.data = nil
            return
        }
        
        // setup chart
        let showAsMg = UserDefaults.standard.bloodGlucoseUnitIsMgDl
        
        let urgentHighInMg = UserDefaults.standard.urgentHighMarkValue
        let highInMg = UserDefaults.standard.highMarkValue
        let lowInMg = UserDefaults.standard.lowMarkValue
        let urgentLowInMg = UserDefaults.standard.urgentLowMarkValue
        
        var urgentHighValues = [ChartDataEntry]()
        var highValues = [ChartDataEntry]()
        var inRangeValues = [ChartDataEntry]()
        var lowValues = [ChartDataEntry]()
        var urgentLowValues = [ChartDataEntry]()
        var currentValues = [ChartDataEntry]()
        
        let isLastReadingCurrent: Bool
        if let lr = readings.last, Date().timeIntervalSince(lr.timeStamp) < Date.minuteInSeconds * 11 {
            isLastReadingCurrent = true
            
        } else {
            isLastReadingCurrent = false
        }
        
        for (i, r) in readings.enumerated() {
            let bgValue = showAsMg ? r.calculatedValue : r.calculatedValue.mgdlToMmol()
            let chartDataEntry = ChartDataEntry(x: r.timeStamp.timeIntervalSince1970, y: bgValue, data: r)
            
            if i >= readings.count - 1 && isLastReadingCurrent {
                currentValues.append(chartDataEntry)
                break
            }
            
            if r.calculatedValue >= urgentHighInMg {
                urgentHighValues.append(chartDataEntry)

            } else if r.calculatedValue >= highInMg {
                highValues.append(chartDataEntry)
                
            } else if r.calculatedValue > lowInMg {
                inRangeValues.append(chartDataEntry)
                
            } else if r.calculatedValue >= urgentLowInMg {
                lowValues.append(chartDataEntry)
                    
            } else {
                urgentLowValues.append(chartDataEntry)
            }
        }
        
        let urgentHighDataSet = ScatterChartDataSet(entries: urgentHighValues)
        urgentHighDataSet.setColor(ConstantsGlucoseChart.glucoseUrgentRangeColor)
        
        let highDataSet = ScatterChartDataSet(entries: highValues)
        highDataSet.setColor(ConstantsGlucoseChart.glucoseNotUrgentRangeColor)
        
        let inRangeDataSet = ScatterChartDataSet(entries: inRangeValues)
        inRangeDataSet.setColor(ConstantsGlucoseChart.glucoseInRangeColor)
        
        let lowDataSet = ScatterChartDataSet(entries: lowValues)
        lowDataSet.setColor(ConstantsGlucoseChart.glucoseNotUrgentRangeColor)
        
        let urgentLowDataSet = ScatterChartDataSet(entries: urgentLowValues)
        urgentLowDataSet.setColor(ConstantsGlucoseChart.glucoseUrgentRangeColor)
        
        let currentDataSet = ScatterChartDataSet(entries: currentValues)
        if isLastReadingCurrent, let lr = readings.last {
            if lr.calculatedValue >= urgentHighInMg || lr.calculatedValue <= urgentLowInMg {
                currentDataSet.setColor(ConstantsGlucoseChart.glucoseUrgentRangeColor)
                
            } else if lr.calculatedValue >= highInMg || lr.calculatedValue <= lowInMg {
                currentDataSet.setColor(ConstantsGlucoseChart.glucoseNotUrgentRangeColor)

            } else {
                currentDataSet.setColor(ConstantsGlucoseChart.glucoseInRangeColor)
            }
        }
        chartCurrentDataSet = currentDataSet
        
        chartView.xAxis.axisMinimum = fromDate.timeIntervalSince1970
        // append 10 miniuts to make the current dot more visible
        chartView.xAxis.axisMaximum = toDate.timeIntervalSince1970 + Date.minuteInSeconds * 10
        
        let data = ScatterChartData(dataSets: [
            urgentHighDataSet,
            highDataSet,
            inRangeDataSet,
            lowDataSet,
            urgentLowDataSet,
            currentDataSet
        ])
        
        for s in data.dataSets {
            guard let scatterDataSet = s as? ScatterChartDataSet else {
                continue
            }
            applyDataSetStyle(dataSet: scatterDataSet)
            applyDataShapeSize(dataSet: scatterDataSet)
        }
        
        applyCurrentDataSetStyle(dataSet: currentDataSet)
        
        chartView.data = data
        
        let xRange = calChartHoursSeconds(chartHoursId: chartHours)
        chartView.setVisibleXRange(minXRange: xRange, maxXRange: xRange)
        
        chartView.moveViewToX(chartView.xAxis.axisMaximum  - xRange)
    }
    
    private func calChartHoursSeconds(chartHoursId: Int) -> Double {
        let xRange: Double
        switch chartHoursId {
        case ChartHours.H1:
            xRange = Date.hourInSeconds
        case ChartHours.H3:
            xRange = Date.hourInSeconds * 3
        case ChartHours.H6:
            xRange = Date.hourInSeconds * 6
        case ChartHours.H12:
            xRange = Date.hourInSeconds * 12
        case ChartHours.H24:
            xRange = Date.hourInSeconds * 24
        default:
            xRange = Date.hourInSeconds * 3
        }
        return xRange
    }
    
    private func applyDataSetStyle(dataSet: ScatterChartDataSet) {
        dataSet.setScatterShape(.circle)
        dataSet.drawValuesEnabled = false
        dataSet.drawHorizontalHighlightIndicatorEnabled = false
        dataSet.highlightColor = .white
        dataSet.axisDependency = .right
        
        dataSet.highlightEnabled = false
    }
    
    private func applyDataShapeSize(dataSet: ScatterChartDataSet) {
        let shapeSize: CGFloat
        switch chartHours
        {
        case ChartHours.H1:
            shapeSize = ConstantsGlucoseChart.glucoseCircleDiameter1h
        case ChartHours.H3:
            shapeSize = ConstantsGlucoseChart.glucoseCircleDiameter3h
        case ChartHours.H6:
            shapeSize = ConstantsGlucoseChart.glucoseCircleDiameter6h
        case ChartHours.H12:
            shapeSize = ConstantsGlucoseChart.glucoseCircleDiameter12h
        case ChartHours.H24:
            shapeSize = ConstantsGlucoseChart.glucoseCircleDiameter24h
        default:
            shapeSize = ConstantsGlucoseChart.glucoseCircleDiameter3h
            break
        }
        dataSet.scatterShapeSize = shapeSize
    }
    
    private func applyCurrentDataSetStyle(dataSet: ScatterChartDataSet) {
        dataSet.scatterShapeSize = dataSet.scatterShapeSize * 1.5
        dataSet.scatterShapeHoleRadius = dataSet.scatterShapeSize * 0.25
        dataSet.scatterShapeHoleColor = ConstantsUI.contentBackgroundColor
    }
    
    private func applyChartHours() {
        let highestVisibleX = chartView.highestVisibleX
        let xRange = calChartHoursSeconds(chartHoursId: chartHours)
        chartView.setVisibleXRange(minXRange: xRange, maxXRange: xRange)
        
        if chartHours == ChartHours.H24 ||
            chartHours == ChartHours.H12 {
            chartView.xAxis.granularity = Date.hourInSeconds * 3 // 2 hours do not work, why?
            
        } else {
            chartView.xAxis.granularity = Date.hourInSeconds
        }
        
        if let data = chartView.data {
            for s in data.dataSets {
                guard let scatterDataSet = s as? ScatterChartDataSet else {
                    continue
                }
                applyDataShapeSize(dataSet: scatterDataSet)
            }
        }
        
        if let currentDataSet = chartCurrentDataSet {
            applyCurrentDataSetStyle(dataSet: currentDataSet)
        }
        
        chartView.notifyDataSetChanged()
        
        // keep the latest time not changed
        chartView.moveViewToX(highestVisibleX - xRange)
    }
}

fileprivate class HourAxisValueFormatter: IAxisValueFormatter {
    
    func stringForValue(_ value: Double, axis: AxisBase?) -> String {
        let date = Date(timeIntervalSince1970: value)
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "HH"
        return dateFormatter.string(from: date)
    }
    
}
