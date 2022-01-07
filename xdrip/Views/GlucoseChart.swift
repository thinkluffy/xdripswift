//
//  GlucoseChart.swift
//  xdrip
//
//  Created by Yuanbin Cai on 2021/11/27.
//  Copyright © 2021 Johan Degraeve. All rights reserved.
//

import UIKit
import Charts

protocol GlucoseChartDelegate: AnyObject {

    func chartReadingSelected(_ glucoseChart: GlucoseChart, reading: BgReading)

    func chartReadingNothingSelected(_ glucoseChart: GlucoseChart)

    func chartDidLongPressed(_ glucoseChart: GlucoseChart)
}

extension GlucoseChartDelegate {

    func chartReadingSelected(_ glucoseChart: GlucoseChart, reading: BgReading) {
    }

    func chartReadingNothingSelected(_ glucoseChart: GlucoseChart) {
    }

    func chartDidLongPressed(_ glucoseChart: GlucoseChart) {
    }
}

class GlucoseChart: UIView {

    private static let log = Log(type: GlucoseChart.self)

    private lazy var chartView = LineChartView()

    private lazy var urgentHighLine = ChartLimitLine()
    private lazy var highLine = ChartLimitLine()
    private lazy var lowLine = ChartLimitLine()
    private lazy var rangeTopLine = ChartLimitLine()
    private lazy var rangeBottomLine = ChartLimitLine()

    private var chartHistoryDataSet: LineChartDataSet?
    private var chartCurrentOneDataSet: LineChartDataSet?

    var chartHours = ChartHours.H3 {
        didSet {
            applyChartHours()
        }
    }

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

    weak var delegate: GlucoseChartDelegate?

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

        let longPressRecognizer = UILongPressGestureRecognizer(closure: { recognizer in
            if self.isLongPressSupported {
                self.delegate?.chartDidLongPressed(self)
            }
        })
        chartView.addGestureRecognizer(longPressRecognizer)
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
        if chartHours == ChartHours.H24 ||
                   chartHours == ChartHours.H12 {
            xAxis.granularity = Date.hourInSeconds * 3 // 2 hours do not work, why?

        } else {
            xAxis.granularity = Date.hourInSeconds
        }
        xAxis.labelCount = 13 // make the x labels step by 1 hour, do not know why

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

    func show(readings: [BgReading]?, from fromDate: Date, to toDate: Date, aheadSeconds: Double = 0) {
        GlucoseChart.log.d("==> showReadings")

        applySettings()

        // setup chart
        let showAsMg = UserDefaults.standard.bloodGlucoseUnitIsMgDl

        let urgentHighInMg = UserDefaults.standard.urgentHighMarkValue
        let highInMg = UserDefaults.standard.highMarkValue
        let lowInMg = UserDefaults.standard.lowMarkValue
        let urgentLowInMg = UserDefaults.standard.urgentLowMarkValue

        // to avoid labels overlapping
        if abs(urgentHighInMg - UserDefaults.standard.chartHeight) < 30 {
            rangeTopLine.label = ""
        }

        if abs(lowInMg - Constants.minBgMgDl) < 30 {
            rangeBottomLine.label = ""
        }

        guard let readings = readings, !readings.isEmpty else {
            GlucoseChart.log.i("readings are nil, nothing to show")

            // put a placeholder to avoid showing default No Data view

            chartView.xAxis.axisMinimum = fromDate.timeIntervalSince1970
            // append 10 miniuts to make the current dot more visible
            chartView.xAxis.axisMaximum = toDate.timeIntervalSince1970 + aheadSeconds

            var placeholderEntries = [ChartDataEntry]()
            let placeholderEntry = ChartDataEntry(x: toDate.timeIntervalSince1970, y: highInMg.mgdlToMmol(mgdl: showAsMg))
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
            return
        }

        var values = [ChartDataEntry]()
        var currentValues = [ChartDataEntry]()

        let filteredBgReadings = filterReadingsIfNeeded(readings)

        let isLastReadingCurrent: Bool
        if let lr = filteredBgReadings.last, Date().timeIntervalSince(lr.timeStamp) < Date.minuteInSeconds * 11 {
            isLastReadingCurrent = true

        } else {
            isLastReadingCurrent = false
        }

        var circleColors = [NSUIColor]()
        for (i, r) in filteredBgReadings.enumerated() {
            let bgValue = showAsMg ? r.calculatedValue : r.calculatedValue.mgdlToMmol()
            let chartDataEntry = ChartDataEntry(x: r.timeStamp.timeIntervalSince1970, y: bgValue, data: r)

            if i >= filteredBgReadings.count - 1 && isLastReadingCurrent {
                currentValues.append(chartDataEntry)
                break
            }

            if r.calculatedValue >= urgentHighInMg {
                circleColors.append(ConstantsGlucoseChart.glucoseUrgentRangeColor)

            } else if r.calculatedValue >= highInMg {
                circleColors.append(ConstantsGlucoseChart.glucoseNotUrgentRangeColor)

            } else if r.calculatedValue > lowInMg {
                circleColors.append(ConstantsGlucoseChart.glucoseInRangeColor)

            } else if r.calculatedValue >= urgentLowInMg {
                circleColors.append(ConstantsGlucoseChart.glucoseNotUrgentRangeColor)

            } else {
                circleColors.append(ConstantsGlucoseChart.glucoseUrgentRangeColor)
            }
            values.append(chartDataEntry)
        }

        let dataSet = LineChartDataSet(entries: values)
        let currentOneDataSet = LineChartDataSet(entries: currentValues)

        chartHistoryDataSet = dataSet
        chartCurrentOneDataSet = currentOneDataSet

        if isLastReadingCurrent, let lr = filteredBgReadings.last {
            if lr.calculatedValue >= urgentHighInMg || lr.calculatedValue <= urgentLowInMg {
                currentOneDataSet.setCircleColor(ConstantsGlucoseChart.glucoseUrgentRangeColor)

            } else if lr.calculatedValue >= highInMg || lr.calculatedValue <= lowInMg {
                currentOneDataSet.setCircleColor(ConstantsGlucoseChart.glucoseNotUrgentRangeColor)

            } else {
                currentOneDataSet.setCircleColor(ConstantsGlucoseChart.glucoseInRangeColor)
            }
        }
        currentOneDataSet.circleHoleColor = ConstantsUI.contentBackgroundColor

        chartView.xAxis.axisMinimum = fromDate.timeIntervalSince1970
        // append 10 miniuts to make the current dot more visible
        chartView.xAxis.axisMaximum = toDate.timeIntervalSince1970 + aheadSeconds

        let data = LineChartData(dataSets: [
            dataSet,
            currentOneDataSet
        ])

        for s in data.dataSets {
            guard let dataSet = s as? LineChartDataSet else {
                continue
            }
            applyDataSetStyle(dataSet: dataSet)
            applyDataShapeSize(dataSet: dataSet)
        }

        dataSet.circleColors = circleColors
        applyCurrentDataShapeSize(dataSet: currentOneDataSet)

        chartView.data = data
    }

    func moveXAxisToTrailing() {
        let xRange = calChartHoursSeconds(chartHoursId: chartHours)
        chartView.setVisibleXRange(minXRange: xRange, maxXRange: xRange)

        chartView.moveViewToX(chartView.xAxis.axisMaximum - xRange)
    }

    func moveCurrentToCenter() {
        let xRange = calChartHoursSeconds(chartHoursId: chartHours)
        chartView.setVisibleXRange(minXRange: xRange, maxXRange: xRange)

        chartView.moveViewToX(Date().timeIntervalSince1970 - xRange / 2)
    }

    func unHighlightAll() {
        chartView.highlightValues(nil)
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

    private func applyDataSetStyle(dataSet: LineChartDataSet) {
        dataSet.drawValuesEnabled = false
        dataSet.drawHorizontalHighlightIndicatorEnabled = false
        dataSet.axisDependency = .right
        dataSet.lineWidth = 0
        dataSet.setColor(.clear)
        dataSet.highlightColor = .white

        dataSet.highlightEnabled = highlightEnabled
    }

    private func applyDataShapeSize(dataSet: LineChartDataSet) {
        let shapeSize: CGFloat
        switch chartHours {
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
        dataSet.circleRadius = shapeSize / 2
    }

    private func applyCurrentDataShapeSize(dataSet: LineChartDataSet) {
        dataSet.circleRadius = dataSet.circleRadius * 1.5
        dataSet.circleHoleRadius = dataSet.circleRadius * 0.5
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
                guard let dataSet = s as? LineChartDataSet else {
                    continue
                }
                applyDataShapeSize(dataSet: dataSet)
            }
        }

        if let currentOneDataSet = chartCurrentOneDataSet {
            applyCurrentDataShapeSize(dataSet: currentOneDataSet)
        }

        chartView.notifyDataSetChanged()

        // keep the latest time not changed
        chartView.moveViewToX(highestVisibleX - xRange)
    }

    override func prepareForInterfaceBuilder() {
        initialize()
    }
}

extension GlucoseChart: ChartViewDelegate {

    func chartValueSelected(_ chartView: ChartViewBase, entry: ChartDataEntry, highlight: Highlight) {
        guard let reading = entry.data as? BgReading else {
            return
        }
        delegate?.chartReadingSelected(self, reading: reading)
    }

    func chartValueNothingSelected(_ chartView: ChartViewBase) {
        delegate?.chartReadingNothingSelected(self)
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
        dateFormatter.dateFormat = dateFormat
        return dateFormatter.string(from: date)
    }
}
