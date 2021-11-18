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

    @IBOutlet weak var titieBar: UIView!
    @IBOutlet weak var chartCard: UIView!
    @IBOutlet weak var bgLabel: UILabel!
    @IBOutlet weak var chartView: ScatterChartView!

    private var presenter: ChartDetailsP!

    override func viewDidLoad() {
        super.viewDidLoad()
        
        instancePresenter()
        
        setupView()
        
        presenter.loadData()
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

        let yAxis = chartView.rightAxis
        yAxis.labelFont = .systemFont(ofSize: 10, weight: .light)
//        yAxis.axisMinimum = 0
        yAxis.labelTextColor = .white
        yAxis.drawGridLinesEnabled = false
        yAxis.axisLineColor = ConstantsUI.mainBackgroundColor
        yAxis.axisLineWidth = 2

        let showAsMg = UserDefaults.standard.bloodGlucoseUnitIsMgDl
        let urgentHigh = UserDefaults.standard.urgentHighMarkValue.mgdlToMmol(mgdl: showAsMg)
        let high = UserDefaults.standard.highMarkValue.mgdlToMmol(mgdl: showAsMg)
        let low = UserDefaults.standard.lowMarkValue.mgdlToMmol(mgdl: showAsMg)

        let urgentHighLine = ChartLimitLine(limit: urgentHigh, label: urgentHigh.bgValuetoString(mgdl: showAsMg))
        urgentHighLine.lineWidth = 1
        urgentHighLine.lineDashLengths = [5, 5]
        urgentHighLine.labelPosition = .topRight
        urgentHighLine.valueFont = .systemFont(ofSize: 10)
        urgentHighLine.lineColor = .gray
        urgentHighLine.valueTextColor = .white
        
        let highLine = ChartLimitLine(limit: high, label: high.bgValuetoString(mgdl: showAsMg))
        highLine.lineWidth = 1
        highLine.lineDashLengths = [5, 5]
        highLine.labelPosition = .topRight
        highLine.valueFont = .systemFont(ofSize: 10)
        highLine.lineColor = .gray
        highLine.valueTextColor = .white
        
        let lowLine = ChartLimitLine(limit: low, label: low.bgValuetoString(mgdl: showAsMg))
        lowLine.lineWidth = 1
        lowLine.lineDashLengths = [5, 5]
        lowLine.labelPosition = .topRight
        lowLine.valueFont = .systemFont(ofSize: 10)
        lowLine.lineColor = .gray
        lowLine.valueTextColor = .white
        
        yAxis.addLimitLine(urgentHighLine)
        yAxis.addLimitLine(highLine)
        yAxis.addLimitLine(lowLine)
        
        yAxis.axisMaximum = showAsMg ? 300 : 16.6
        yAxis.axisMinimum = showAsMg ? 40 : 2.2
        
        yAxis.drawLabelsEnabled = false
        yAxis.drawTopYLabelEntryEnabled = true
    }
}

extension ChartDetailsViewController: ChartDetailsV {
    
    func showReadings(_ readings: [BgReading]?, from fromDate: Date, to toDate: Date) {
        guard let readings = readings else {
            ChartDetailsViewController.log.e("reading is nil, nothing to show")
            chartView.data = nil
            return
        }
        
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
        
        let data = ScatterChartData(dataSets: [urgentHighDataSet, highDataSet, inRangeDataSet, lowDataSet, urgentLowDataSet])

        chartView.data = data
        
        chartView.setVisibleXRange(minXRange: Date.hourInSeconds * 6, maxXRange: Date.hourInSeconds * 6)
    }
    
    private func applyDataSetStyle(dataSet: ScatterChartDataSet) {
        dataSet.setScatterShape(.circle)
        dataSet.drawValuesEnabled = false
        dataSet.drawHorizontalHighlightIndicatorEnabled = false
    }
}

extension ChartDetailsViewController: ChartViewDelegate {
    
    @objc func chartValueSelected(_ chartView: ChartViewBase, entry: ChartDataEntry, highlight: Highlight) {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "HH:mm"
        let timestamp = dateFormatter.string(from: Date(timeIntervalSince1970: entry.x))
        ChartDetailsViewController.log.d("==> chartValueSelected, (\(timestamp), \(entry.y))")
        
        bgLabel.text = "\(timestamp) \(entry.y.bgValuetoString(mgdl: UserDefaults.standard.bloodGlucoseUnitIsMgDl))"
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

