//
//  DailyTrendChart.swift
//  xdrip
//
//  Created by Yuanbin Cai on 2022/1/15.
//  Copyright © 2022 zDrip. All rights reserved.
//

import UIKit

import UIKit
import Charts

protocol DailyTrendChartDelegate: AnyObject {

    func dailyTrendChartItemSelected(_ chart: DailyTrendChart, item: DailyTrend.DailyTrendItem)

    func dailyTrendChartItemNothingSelected(_ chart: DailyTrendChart)

}

class DailyTrendChart: UIView {

    private static let log = Log(type: DailyTrendChart.self)

    private lazy var chartView = LineChartView()

    private lazy var urgentHighLine = ChartLimitLine()
    private lazy var highLine = ChartLimitLine()
    private lazy var lowLine = ChartLimitLine()
    private lazy var rangeTopLine = ChartLimitLine()
    private lazy var rangeBottomLine = ChartLimitLine()

    private var chartHistoryDataSet: LineChartDataSet?
    private var chartCurrentOneDataSet: LineChartDataSet?

    var dragMoveHighlightFirst: Bool {
        get {
            chartView.dragMoveHighlightFirst
        }
        set {
            chartView.dragMoveHighlightFirst = newValue
        }
    }

    var dragEnabled: Bool {
        get {
            chartView.dragEnabled
        }
        set {
            chartView.dragEnabled = newValue
        }
    }

    var dateFormat = "HH" {
        didSet {
            chartView.xAxis.valueFormatter = HourAxisValueFormatter(dateFormat: dateFormat)
        }
    }

    var highlightEnabled = false {
        didSet {
            chartHistoryDataSet?.highlightEnabled = highlightEnabled
            chartCurrentOneDataSet?.highlightEnabled = highlightEnabled
        }
    }

    var isLongPressSupported = false

    weak var delegate: DailyTrendChartDelegate?

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
        applySettings()
        showNoData()
    }

    private func setupChart() {
        chartView.delegate = self

        chartView.dragEnabled = false
        chartView.chartDescription?.enabled = false
        chartView.setScaleEnabled(false)
        chartView.pinchZoomEnabled = false
        chartView.legend.enabled = false

        let xAxis = chartView.xAxis
        xAxis.labelFont = .systemFont(ofSize: 12)
        xAxis.labelTextColor = .white
        xAxis.valueFormatter = HourAxisValueFormatter(dateFormat: dateFormat)
        xAxis.labelPosition = .bottom
        xAxis.gridColor = ConstantsUI.mainBackgroundColor
        xAxis.gridLineWidth = 2
        xAxis.axisLineColor = ConstantsUI.mainBackgroundColor
        xAxis.axisLineWidth = 2
        xAxis.granularity = Date.hourInSeconds * 3 // 2 hours do not work, why?
        xAxis.labelCount = 13 // make the x labels step by 1 hour, do not know why
        xAxis.axisMinimum = 0
        xAxis.axisMaximum = Date.dayInSeconds
        
        chartView.leftAxis.enabled = false

        // leave space for limit labels outside viewport
        chartView.setExtraOffsets(left: 0, top: 0, right: 35, bottom: 0)

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

        let chartHeight = UserDefaults.standard.chartHeight

        let yAxis = chartView.rightAxis
        yAxis.axisMaximum = showAsMg ? chartHeight : chartHeight.mgdlToMmol()
        yAxis.axisMinimum = showAsMg ? Constants.minBgMgDl : Constants.minBgMgDl.mgdlToMmol()

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

    private func filterReadingsIfNeeded(_ readings: [BgReading]) -> [BgReading] {
        guard UserDefaults.standard.chartDots5MinsApart else {
            return readings
        }

        var filteredBgReadings = [BgReading]()
        var lastShownReading: BgReading?

        for r in readings {
            if lastShownReading == nil ||
                       r.timeStamp.timeIntervalSince(lastShownReading!.timeStamp) > 4.5 * Date.minuteInSeconds {
                filteredBgReadings.append(r)
                lastShownReading = r
            }
        }

        return filteredBgReadings
    }

    func cleanUpMemory() {
        DailyTrendChart.log.d("==> cleanUpMemory")
        showNoData()
    }

    func showNoData() {
        // put a placeholder to avoid showing default No Data view
        var placeholderEntries = [ChartDataEntry]()
        let placeholderEntry = ChartDataEntry(x: chartView.xAxis.axisMinimum,
                                              y: UserDefaults.standard.highMarkValue.mgdlToMmol(mgdl: UserDefaults.standard.bloodGlucoseUnitIsMgDl))
        placeholderEntries.append(placeholderEntry)
        let placeholderDataSet = LineChartDataSet(entries: placeholderEntries)
        placeholderDataSet.setColor(.clear)
        placeholderDataSet.highlightEnabled = false
        placeholderDataSet.drawCirclesEnabled = false
        placeholderDataSet.drawCircleHoleEnabled = false
        placeholderDataSet.axisDependency = .right

        let data = LineChartData(dataSets: [
            placeholderDataSet
        ])
        chartView.data = data
    }
    
    func show(dailyTrendItems: [DailyTrend.DailyTrendItem]) {
        DailyTrendChart.log.d("==> showDailyTrendItems")
        
        applySettings()
        
        // setup chart
        let showAsMg = UserDefaults.standard.bloodGlucoseUnitIsMgDl

        let urgentHighInMg = UserDefaults.standard.urgentHighMarkValue
        let lowInMg = UserDefaults.standard.lowMarkValue

        // to avoid labels overlapping
        if abs(urgentHighInMg - UserDefaults.standard.chartHeight) < 30 {
            rangeTopLine.label = ""
        }

        if abs(lowInMg - Constants.minBgMgDl) < 30 {
            rangeBottomLine.label = ""
        }
        
        guard !dailyTrendItems.isEmpty else {
            DailyTrendChart.log.i("dailyTrendItems are nil, nothing to show")
            showNoData()
            return
        }

        var highValues = [ChartDataEntry]()
        var lowValues = [ChartDataEntry]()

        var medianHighValues = [ChartDataEntry]()
        var medianLowValues = [ChartDataEntry]()

        var medianValues = [ChartDataEntry]()

        for item in dailyTrendItems {
            guard item.isValid else {
                DailyTrendChart.log.d("item is NOT valid, \(item.timeInterval)")
                continue
            }
            
            if let median = item.median,
               let high = item.high, let low = item.low,
               let medianHigh = item.medianHigh, let medianLow = item.medianLow {

                let highEntry = ChartDataEntry(x: item.timeInterval, y: showAsMg ? high : high.mgdlToMmol())
                highValues.append(highEntry)
               
                let lowEntry = ChartDataEntry(x: item.timeInterval, y: showAsMg ? low : low.mgdlToMmol())
                lowValues.append(lowEntry)

                let medianHighEntry = ChartDataEntry(x: item.timeInterval, y: showAsMg ? medianHigh : medianHigh.mgdlToMmol())
                medianHighValues.append(medianHighEntry)

                let medianLowEntry = ChartDataEntry(x: item.timeInterval, y: showAsMg ? medianLow : medianLow.mgdlToMmol())
                medianLowValues.append(medianLowEntry)

                let medianEntry = ChartDataEntry(x: item.timeInterval,
                                                 y: showAsMg ? median : median.mgdlToMmol(),
                                                 data: item)
                medianValues.append(medianEntry)
            }
        }

        let highDataSet = LineChartDataSet(entries: highValues)
        let lowDataSet = LineChartDataSet(entries: lowValues)

        let medianHighDataSet = LineChartDataSet(entries: medianHighValues)
        let medianLowDataSet = LineChartDataSet(entries: medianLowValues)

        let medianDataSet = LineChartDataSet(entries: medianValues)

        applyDataSetStyle(dataSet: highDataSet)
        applyDataSetStyle(dataSet: lowDataSet)

        applyDataSetStyle(dataSet: medianHighDataSet)
        applyDataSetStyle(dataSet: medianLowDataSet)

        applyDataSetStyle(dataSet: medianDataSet)

        highDataSet.lineWidth = 0
        lowDataSet.lineWidth = 0

        medianHighDataSet.lineWidth = 0
        medianLowDataSet.lineWidth = 0

        medianDataSet.lineWidth = 3
        medianDataSet.drawCirclesEnabled = true
        medianDataSet.circleRadius = 1.5
        medianDataSet.setCircleColor(.white)
        medianDataSet.highlightEnabled = true
        
        highDataSet.fillColor = .white
        highDataSet.fillAlpha = 0.2
        highDataSet.drawFilledEnabled = true
        highDataSet.fillFormatterForEachEntry = FillFormatterForEachEntry {
            (entry: ChartDataEntry, dataSet: ILineChartDataSet, _) -> CGFloat in
            
            let index = dataSet.entryIndex(entry: entry)
            return lowDataSet[index].y
        }
        
        medianHighDataSet.fillColor = .white
        medianHighDataSet.fillAlpha = 0.2
        medianHighDataSet.drawFilledEnabled = true
        medianHighDataSet.fillFormatterForEachEntry = FillFormatterForEachEntry {
            (entry: ChartDataEntry, dataSet: ILineChartDataSet, _) -> CGFloat in
            
            let index = dataSet.entryIndex(entry: entry)
            return medianLowDataSet[index].y
        }
        
        let data = LineChartData(dataSets: [
            highDataSet,
            lowDataSet,
            medianHighDataSet,
            medianLowDataSet,
            medianDataSet
        ])
        chartView.data = data
        
        chartView.animate(xAxisDuration: 2.5)
    }
    
    private func applyDataSetStyle(dataSet: LineChartDataSet) {
        dataSet.drawValuesEnabled = false
        dataSet.drawHorizontalHighlightIndicatorEnabled = false
        dataSet.axisDependency = .right
        dataSet.setColor(.white)
        dataSet.highlightColor = .white
        dataSet.drawCirclesEnabled = false
        dataSet.drawCircleHoleEnabled = false
        
//        dataSet.mode = .cubicBezier

        dataSet.highlightEnabled = false
    }
    
    func unHighlightAll() {
        chartView.highlightValues(nil)
        // chartView did not call chartValueNothingSelected, seems a bug
        delegate?.dailyTrendChartItemNothingSelected(self)
    }

    private var chartHoursSeconds: Double {
        Date.hourInSeconds * 24
    }

    override func prepareForInterfaceBuilder() {
        initialize()
    }
}

extension DailyTrendChart: ChartViewDelegate {

    func chartValueSelected(_ chartView: ChartViewBase, entry: ChartDataEntry, highlight: Highlight) {
        guard let item = entry.data as? DailyTrend.DailyTrendItem else {
            return
        }
        delegate?.dailyTrendChartItemSelected(self, item: item)
    }

    func chartValueNothingSelected(_ chartView: ChartViewBase) {
        delegate?.dailyTrendChartItemNothingSelected(self)
    }
}

fileprivate class HourAxisValueFormatter: IAxisValueFormatter {

    let dateFormat: String

    init(dateFormat: String) {
        self.dateFormat = dateFormat
    }

    func stringForValue(_ value: Double, axis: AxisBase?) -> String {
        let date = Date(timeIntervalSince1970: value)
        let dateFormatter = DateFormatter()
        dateFormatter.timeZone = TimeZone(secondsFromGMT: 0)
        dateFormatter.dateFormat = dateFormat
        
        return dateFormatter.string(from: date)
    }
}

