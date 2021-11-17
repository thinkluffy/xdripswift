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
        chartView.maxVisibleCount = 200
        chartView.pinchZoomEnabled = true
        
        let yAxis = chartView.rightAxis
        yAxis.labelFont = .systemFont(ofSize: 10, weight: .light)
        yAxis.axisMinimum = 0
        yAxis.labelTextColor = .white
        
        chartView.leftAxis.enabled = false
        
        chartView.xAxis.labelPosition = .bottom

        let xAxis = chartView.xAxis
        xAxis.labelFont = .systemFont(ofSize: 10, weight: .light)
        xAxis.labelTextColor = .white
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
        let timeRange = toDate.timeIntervalSince(fromDate)
        
        let urgentHigh = UserDefaults.standard.urgentHighMarkValue
        let high = UserDefaults.standard.highMarkValue
        let low = UserDefaults.standard.lowMarkValue
        let urgentLow = UserDefaults.standard.urgentLowMarkValue
        
        var urgentHighValues = [ChartDataEntry]()
        var highValues = [ChartDataEntry]()
        var inRangeValues = [ChartDataEntry]()
        var lowValues = [ChartDataEntry]()
        var urgentLowValues = [ChartDataEntry]()

        for r in readings {
            let bgValue = showAsMg ? r.calculatedValue : r.calculatedValue.mgdlToMmol()
            let chartDataEntry = ChartDataEntry(x: r.timeStamp.timeIntervalSince(fromDate) / timeRange, y: bgValue, data: r)
            if r.calculatedValue >= urgentHigh {
                urgentHighValues.append(chartDataEntry)
                
            } else if r.calculatedValue >= high {
                highValues.append(chartDataEntry)
                
            } else if r.calculatedValue > low {
                inRangeValues.append(chartDataEntry)
                
            } else if r.calculatedValue > urgentLow {
                lowValues.append(chartDataEntry)
                
            } else {
                urgentLowValues.append(chartDataEntry)
            }
        }
        
        let urgentHighDataSet = ScatterChartDataSet(entries: urgentHighValues, label: "UrgentHigh")
        urgentHighDataSet.setScatterShape(.circle)
        urgentHighDataSet.setColor(ConstantsGlucoseChart.glucoseUrgentRangeColor)
        urgentHighDataSet.scatterShapeSize = ConstantsGlucoseChart.glucoseCircleDiameter3h
        
        let highDataSet = ScatterChartDataSet(entries: highValues, label: "High")
        highDataSet.setScatterShape(.circle)
        highDataSet.setColor(ConstantsGlucoseChart.glucoseNotUrgentRangeColor)
        highDataSet.scatterShapeSize = ConstantsGlucoseChart.glucoseCircleDiameter3h
        
        let inRangeDataSet = ScatterChartDataSet(entries: inRangeValues, label: "InRange")
        inRangeDataSet.setScatterShape(.circle)
        inRangeDataSet.setColor(ConstantsGlucoseChart.glucoseInRangeColor)
        inRangeDataSet.scatterShapeSize = ConstantsGlucoseChart.glucoseCircleDiameter3h
        
        let lowDataSet = ScatterChartDataSet(entries: lowValues, label: "Low")
        lowDataSet.setScatterShape(.circle)
        lowDataSet.setColor(ConstantsGlucoseChart.glucoseNotUrgentRangeColor)
        lowDataSet.scatterShapeSize = ConstantsGlucoseChart.glucoseCircleDiameter3h
        
        let urgentLowDataSet = ScatterChartDataSet(entries: urgentLowValues, label: "UrgentLow")
        urgentLowDataSet.setScatterShape(.circle)
        urgentLowDataSet.setColor(ConstantsGlucoseChart.glucoseUrgentRangeColor)
        urgentLowDataSet.scatterShapeSize = ConstantsGlucoseChart.glucoseCircleDiameter3h
        
        let data = ScatterChartData(dataSets: [urgentHighDataSet, highDataSet, inRangeDataSet, lowDataSet, urgentLowDataSet])
        data.setValueFont(.systemFont(ofSize: 7, weight: .light))

        chartView.setVisibleXRange(minXRange: 0.5, maxXRange: 1)

        chartView.data = data
    }
}

extension ChartDetailsViewController: ChartViewDelegate {
    
    @objc func chartValueSelected(_ chartView: ChartViewBase, entry: ChartDataEntry, highlight: Highlight) {
        ChartDetailsViewController.log.d("====> chartValueSelected, (\(entry.x), \(entry.y))")
    }
}
