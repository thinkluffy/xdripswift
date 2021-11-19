//
//  ChartDetailsViewController.swift
//  xdrip
//
//  Created by Yuanbin Cai on 2021/11/9.
//  Copyright © 2021 Johan Degraeve. All rights reserved.
//

import UIKit
import Charts

class ChartDetailsViewController: UIViewController {

    private static let log = Log(type: ChartDetailsViewController.self)

    @IBOutlet weak var titleBar: UIView!
    @IBOutlet weak var chartCard: UIView!
    @IBOutlet weak var bgTimeLabel: UILabel!
    @IBOutlet weak var bgValueLabel: UILabel!
    @IBOutlet weak var chartView: ScatterChartView!

    private var presenter: ChartDetailsP!

    private lazy var calendarTitle: CalendarTitle = {
        let calendarTitle = CalendarTitle()
        return calendarTitle
    }()
    
    private var showingDate: Date?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        instancePresenter()
        
        setupView()
        
        let current = Date()
        presenter.loadData(date: current)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        presenter.onViewDidAppear()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        presenter.onViewWillDisappear()
        super.viewWillDisappear(animated)
    }
    
    @IBAction func exitButtonClicked(_ sender: UIButton) {
        dismiss(animated: false)
    }
    
    // make the ViewController landscape mode
    override public var shouldAutorotate: Bool {
        return false
    }
    
    override public var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return .landscapeLeft
    }
    
    override public var preferredInterfaceOrientationForPresentation: UIInterfaceOrientation {
        return .landscapeLeft
    }
    
    func instancePresenter() {
        presenter = ChartDetailsPresenter(view: self)
    }
    
    private func setupView() {
        titleBar.addSubview(calendarTitle)
        
        calendarTitle.snp.makeConstraints { make in
            make.center.equalToSuperview()
        }
        calendarTitle.delegate = self
        
        setupChart()
    }
    
    private func setupChart() {
        chartView.delegate = self

        chartView.chartDescription?.enabled = false
        
        chartView.dragEnabled = true
        chartView.setScaleEnabled(true)
//        chartView.maxVisibleCount = 200
        chartView.pinchZoomEnabled = true
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
        xAxis.granularity = Date.hourInSeconds
        xAxis.labelCount = 13 // make the x labels step by 1 hour, do not know why
        
        chartView.leftAxis.enabled = false

        let showAsMg = UserDefaults.standard.bloodGlucoseUnitIsMgDl

        let yAxis = chartView.rightAxis
        yAxis.drawGridLinesEnabled = false
        yAxis.drawLabelsEnabled = false
        yAxis.axisLineColor = ConstantsUI.mainBackgroundColor
        yAxis.axisLineWidth = 2
        yAxis.axisMaximum = showAsMg ? 300 : 16.6
        yAxis.axisMinimum = showAsMg ? 40 : 2.2
        
        let urgentHigh = UserDefaults.standard.urgentHighMarkValue.mgdlToMmol(mgdl: showAsMg)
        let high = UserDefaults.standard.highMarkValue.mgdlToMmol(mgdl: showAsMg)
        let low = UserDefaults.standard.lowMarkValue.mgdlToMmol(mgdl: showAsMg)

        let urgentHighLine = ChartLimitLine(limit: urgentHigh, label: urgentHigh.bgValuetoString(mgdl: showAsMg))
        urgentHighLine.lineWidth = 1
        urgentHighLine.lineDashLengths = [5, 5]
        urgentHighLine.labelPosition = .topRight
        urgentHighLine.valueFont = .systemFont(ofSize: 12)
        urgentHighLine.lineColor = .gray
        urgentHighLine.valueTextColor = .white
        
        let highLine = ChartLimitLine(limit: high, label: high.bgValuetoString(mgdl: showAsMg))
        highLine.lineWidth = 1
        highLine.lineDashLengths = [5, 5]
        highLine.labelPosition = .topRight
        highLine.valueFont = .systemFont(ofSize: 12)
        highLine.lineColor = .gray
        highLine.valueTextColor = .white
        
        let lowLine = ChartLimitLine(limit: low, label: low.bgValuetoString(mgdl: showAsMg))
        lowLine.lineWidth = 1
        lowLine.lineDashLengths = [5, 5]
        lowLine.labelPosition = .topRight
        lowLine.valueFont = .systemFont(ofSize: 12)
        lowLine.lineColor = .gray
        lowLine.valueTextColor = .white
        
        let rangeTopLine = ChartLimitLine(limit: yAxis.axisMaximum)
        rangeTopLine.lineWidth = 2
        rangeTopLine.lineColor = ConstantsUI.mainBackgroundColor
        
        yAxis.addLimitLine(urgentHighLine)
        yAxis.addLimitLine(highLine)
        yAxis.addLimitLine(lowLine)
        yAxis.addLimitLine(rangeTopLine)
    }
}

extension ChartDetailsViewController: ChartDetailsV {
    
    func showReadings(_ readings: [BgReading]?, from fromDate: Date, to toDate: Date) {
        guard let readings = readings else {
            ChartDetailsViewController.log.e("reading is nil, nothing to show")
            chartView.data = nil
            return
        }
        
        // setup calendar title
        calendarTitle.dateTime = fromDate
        let isToday = Calendar.current.isDateInToday(fromDate)
        calendarTitle.showRightArrow = !isToday
        
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

        for r in readings {
            let bgValue = showAsMg ? r.calculatedValue : r.calculatedValue.mgdlToMmol()
            let chartDataEntry = ChartDataEntry(x: r.timeStamp.timeIntervalSince1970, y: bgValue, data: r)
            if r.calculatedValue >= urgentHighInMg {
                urgentHighValues.append(chartDataEntry)
                
            } else if r.calculatedValue >= highInMg {
                highValues.append(chartDataEntry)
                
            } else if r.calculatedValue > lowInMg {
                inRangeValues.append(chartDataEntry)
                
            } else if r.calculatedValue > urgentLowInMg {
                lowValues.append(chartDataEntry)
                
            } else {
                urgentLowValues.append(chartDataEntry)
            }
        }
        
        let urgentHighDataSet = ScatterChartDataSet(entries: urgentHighValues)
        applyDataSetStyle(dataSet: urgentHighDataSet)
        urgentHighDataSet.setColor(ConstantsGlucoseChart.glucoseUrgentRangeColor)
        urgentHighDataSet.scatterShapeSize = ConstantsGlucoseChart.glucoseCircleDiameter3h
        
        let highDataSet = ScatterChartDataSet(entries: highValues)
        applyDataSetStyle(dataSet: highDataSet)
        highDataSet.setColor(ConstantsGlucoseChart.glucoseNotUrgentRangeColor)
        highDataSet.scatterShapeSize = ConstantsGlucoseChart.glucoseCircleDiameter3h
        
        let inRangeDataSet = ScatterChartDataSet(entries: inRangeValues)
        applyDataSetStyle(dataSet: inRangeDataSet)
        inRangeDataSet.setColor(ConstantsGlucoseChart.glucoseInRangeColor)
        inRangeDataSet.scatterShapeSize = ConstantsGlucoseChart.glucoseCircleDiameter3h
        
        let lowDataSet = ScatterChartDataSet(entries: lowValues)
        applyDataSetStyle(dataSet: lowDataSet)
        lowDataSet.setColor(ConstantsGlucoseChart.glucoseNotUrgentRangeColor)
        lowDataSet.scatterShapeSize = ConstantsGlucoseChart.glucoseCircleDiameter3h
        
        let urgentLowDataSet = ScatterChartDataSet(entries: urgentLowValues)
        applyDataSetStyle(dataSet: urgentLowDataSet)
        urgentLowDataSet.setColor(ConstantsGlucoseChart.glucoseUrgentRangeColor)
        urgentLowDataSet.scatterShapeSize = ConstantsGlucoseChart.glucoseCircleDiameter3h
        
        chartView.xAxis.axisMinimum = fromDate.timeIntervalSince1970
        chartView.xAxis.axisMaximum = toDate.timeIntervalSince1970
        
        let data = ScatterChartData(dataSets: [urgentHighDataSet, highDataSet, inRangeDataSet, lowDataSet, urgentLowDataSet])
        chartView.data = data
            
        chartView.setVisibleXRange(minXRange: Date.hourInSeconds * 6, maxXRange: Date.hourInSeconds * 6)
        
        // move current time to centerX
        if isToday && showingDate == nil {
            chartView.moveViewToX(min(Date().timeIntervalSince1970 - Date.hourInSeconds * 3,
                                      toDate.timeIntervalSince1970 - Date.hourInSeconds * 6))
        }
        
        showingDate = fromDate
        
        // reset selected bg time and value
        bgTimeLabel.text = "--:--"
        bgValueLabel.text = "---"
        bgValueLabel.textColor = .white
    }
    
    private func applyDataSetStyle(dataSet: ScatterChartDataSet) {
        dataSet.setScatterShape(.circle)
        dataSet.drawValuesEnabled = false
        dataSet.drawHorizontalHighlightIndicatorEnabled = false
        dataSet.axisDependency = .right
    }
}

extension ChartDetailsViewController: ChartViewDelegate {
    
    @objc func chartValueSelected(_ chartView: ChartViewBase, entry: ChartDataEntry, highlight: Highlight) {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "HH:mm"
        let timestamp = dateFormatter.string(from: Date(timeIntervalSince1970: entry.x))
        ChartDetailsViewController.log.d("==> chartValueSelected, (\(timestamp), \(entry.y))")
                
        bgTimeLabel.text = timestamp
        bgValueLabel.text = entry.y.bgValuetoString(mgdl: UserDefaults.standard.bloodGlucoseUnitIsMgDl)
        
        // hard code, so ugly and so work
        if highlight.dataSetIndex == 0 || highlight.dataSetIndex == 4 {
            bgValueLabel.textColor = ConstantsGlucoseChart.glucoseUrgentRangeColor
            
        } else if highlight.dataSetIndex == 1 || highlight.dataSetIndex == 3 {
            bgValueLabel.textColor = ConstantsGlucoseChart.glucoseNotUrgentRangeColor
            
        } else {
            bgValueLabel.textColor = ConstantsGlucoseChart.glucoseInRangeColor
        }
    }
}

extension ChartDetailsViewController: CalendarTitleDelegate {
    
    func calendarLeftButtonDidClick(_ calendarTitle: CalendarTitle, currentTime: Date) {
        if let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: currentTime) {
            presenter.loadData(date: yesterday)
        }
    }
    
    func calendarRightButtonDidClick(_ calendarTitle: CalendarTitle, currentTime: Date) {
        if let nextDay = Calendar.current.date(byAdding: .day, value: 1, to: currentTime) {
            presenter.loadData(date: nextDay)
        }
    }
    
    func calendarTitleDidClick(_ calendarTitle: CalendarTitle) {
        
    }
}

fileprivate class HourAxisValueFormatter: IAxisValueFormatter {
    
    func stringForValue(_ value: Double, axis: AxisBase?) -> String {
        let date = Date(timeIntervalSince1970: value)
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "HH:mm"
        return dateFormatter.string(from: date)
    }
    
}

