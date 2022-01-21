//
//  ChartDetailsViewController.swift
//  xdrip
//
//  Created by Yuanbin Cai on 2021/11/9.
//  Copyright © 2021 zDrip. All rights reserved.
//

import UIKit
import Charts
import FSCalendar

class ChartDetailsViewController: UIViewController {

    private static let log = Log(type: ChartDetailsViewController.self)

    @IBOutlet weak var titleBar: UIView!
    @IBOutlet weak var chartCard: UIView!
    @IBOutlet weak var bgTimeLabel: UILabel!
    @IBOutlet weak var bgValueLabel: UILabel!
    @IBOutlet weak var showStatisticsButton: UIButton!
    @IBOutlet weak var lockMoveButton: UIButton!

    @IBOutlet weak var glucoseChart: GlucoseChart!

    private var presenter: ChartDetailsP!
    
    private var selectedChartHours = ChartHours.h6
    
    private lazy var exitButton: UIButton = {
        let view = UIButton()
        view.setImage(R.image.ic_to_portrait(), for: .normal)
        return view
    }()
    
    private lazy var calendarTitle: CalendarTitle = {
        CalendarTitle()
    }()
    
    private lazy var chartHoursSelection: SingleSelection = {
        SingleSelection()
    }()
    
    private var showingDate: Date?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        instancePresenter()
        
        setupView()
        
        presenter.loadData(date: Date())
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        presenter.onViewDidAppear()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        presenter.onViewWillDisappear()
        super.viewWillDisappear(animated)
    }
    
    // make the ViewController landscape mode
    override public var shouldAutorotate: Bool {
        false
    }
    
    override public var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        .landscapeLeft
    }
    
    override public var preferredInterfaceOrientationForPresentation: UIInterfaceOrientation {
        .landscapeLeft
    }
    
    private func instancePresenter() {
        presenter = ChartDetailsPresenter(view: self)
    }
    
    private func setupView() {
        titleBar.addSubview(exitButton)
        titleBar.addSubview(calendarTitle)
        titleBar.addSubview(chartHoursSelection)
        
        exitButton.snp.makeConstraints { make in
            make.centerY.equalToSuperview()
            make.leading.equalToSuperview().offset(20)
        }
        
        calendarTitle.snp.makeConstraints { make in
            make.centerY.equalToSuperview()
            make.leading.equalTo(exitButton.snp.trailing).offset(20)
        }
        
        chartHoursSelection.snp.makeConstraints { make in
            make.centerY.equalToSuperview()
            make.trailing.equalToSuperview().offset(-10)
            make.height.equalToSuperview()
        }
        
        exitButton.addTarget(self, action: #selector(exitButtonDidClick(_:)), for: .touchUpInside)
        calendarTitle.delegate = self

        var selectionItems = [SingleSelectionItem]()
        selectionItems.append(SingleSelectionItem(id: ChartHours.h1.rawValue, title: "1H"))
        selectionItems.append(SingleSelectionItem(id: ChartHours.h3.rawValue, title: "3H"))
        selectionItems.append(SingleSelectionItem(id: ChartHours.h6.rawValue, title: "6H"))
        selectionItems.append(SingleSelectionItem(id: ChartHours.h12.rawValue, title: "12H"))
        selectionItems.append(SingleSelectionItem(id: ChartHours.h24.rawValue, title: "24H"))

        chartHoursSelection.show(items: selectionItems)
        chartHoursSelection.delegate = self
        chartHoursSelection.select(id: selectedChartHours.rawValue, triggerCallback: false)

        showStatisticsButton.onTap { [unowned self] btn in
            if let date = calendarTitle.dateTime {
                presenter.loadStatistics(date: date)
            }
        }
        
        lockMoveButton.onTap { [unowned self] btn in
            if glucoseChart.dragMoveHighlightFirst {
                btn.setImage(R.image.ic_pushpin_unlock(), for: .normal)
                btn.tintColor = .white
                glucoseChart.dragMoveHighlightFirst = false

            } else {
                btn.setImage(R.image.ic_pushpin_lock()?.withRenderingMode(.alwaysTemplate), for: .normal)
                btn.tintColor = ConstantsUI.accentRed
                glucoseChart.dragMoveHighlightFirst = true
            }
        }
        
        setupChart()
    }
    
    private func setupChart() {
        glucoseChart.delegate = self
        glucoseChart.dragEnabled = true
        glucoseChart.highlightEnabled = true
        glucoseChart.dateFormat = "HH:mm"
        glucoseChart.chartHours = selectedChartHours
        glucoseChart.useBiggerCircleSize = UserDefaults.standard.chartPoints5MinsApart
    }
    
    @objc private func exitButtonDidClick(_ button: UIButton) {
        dismiss(animated: false)
    }
}

extension ChartDetailsViewController: ChartDetailsV {
    
    func show(readings: [BgReading]?, from fromDate: Date, to toDate: Date) {
        // setup calendar title
        calendarTitle.dateTime = fromDate
        let isToday = Calendar.current.isDateInToday(fromDate)
        calendarTitle.showRightArrow = !isToday
        
        // reset selected bg time and value
        glucoseChart.unHighlightAll()
        
        glucoseChart.show(readings: readings, from: fromDate, to: toDate)

        if let readings = readings, !readings.isEmpty {
            showStatisticsButton.enable()
            lockMoveButton.enable()
            
        } else {
            showStatisticsButton.disable()
            lockMoveButton.disable()
        }
        
        if isToday && showingDate == nil {
            glucoseChart.moveCurrentToCenter()
        }
        
        showingDate = fromDate
    }
    
    func show(statistics: StatisticsManager.Statistics, of date: Date) {
        let content = StatisticsSheetContent(statistics: statistics, date: date)
        let sheet = SlideInSheet(sheetContent: content)
        sheet.show(in: view, dimColor: .black.withAlphaComponent(0.5), slideInFrom: .trailing)
    }
    
    private func applyDataSetStyle(dataSet: ScatterChartDataSet) {
        dataSet.setScatterShape(.circle)
        dataSet.drawValuesEnabled = false
        dataSet.drawHorizontalHighlightIndicatorEnabled = false
        dataSet.highlightColor = .white
        dataSet.axisDependency = .right
    }
    
    private func applyDataShapeSize(dataSet: ScatterChartDataSet) {
        dataSet.scatterShapeSize = ConstantsGlucoseChart.glucoseCircleDiameter3h
    }
}

extension ChartDetailsViewController: GlucoseChartDelegate {

    func chartReadingSelected(_ glucoseChart: GlucoseChart, reading: BgReading) {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "HH:mm"
        let timestamp = dateFormatter.string(from: reading.timeStamp)
        
        let showMgDl = UserDefaults.standard.bloodGlucoseUnitIsMgDl
        ChartDetailsViewController.log.d("==> chartValueSelected, (\(timestamp), \(reading.calculatedValue.mgdlToMmol(mgdl: showMgDl)))")
                
        bgTimeLabel.text = timestamp
        bgValueLabel.text = reading.calculatedValue.mgdlToMmolAndToString(mgdl: showMgDl)
                
        let urgentHighInMg = UserDefaults.standard.urgentHighMarkValue
        let highInMg = UserDefaults.standard.highMarkValue
        let lowInMg = UserDefaults.standard.lowMarkValue
        let urgentLowInMg = UserDefaults.standard.urgentLowMarkValue
        
        if reading.calculatedValue >= urgentHighInMg || reading.calculatedValue <= urgentLowInMg {
            bgValueLabel.textColor = ConstantsGlucoseChart.glucoseUrgentRangeColor

        } else if reading.calculatedValue >= highInMg || reading.calculatedValue <= lowInMg {
            bgValueLabel.textColor = ConstantsGlucoseChart.glucoseNotUrgentRangeColor

        } else {
            bgValueLabel.textColor = ConstantsGlucoseChart.glucoseInRangeColor
        }
    }
    
    func chartReadingNothingSelected(_ glucoseChart: GlucoseChart) {
        bgTimeLabel.text = "--:--"
        bgValueLabel.text = "---"
        bgValueLabel.textColor = .white
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
        guard let selectedDate = calendarTitle.dateTime else {
            return
        }
        
        let content = DatePickerSheetContent(selectedDate: selectedDate, slideInFrom: .trailing)
        content.delegate = self
        let sheet = SlideInSheet(sheetContent: content)
        sheet.show(in: view, dimColor: .black.withAlphaComponent(0.5), slideInFrom: .trailing)
    }
}

extension ChartDetailsViewController: SingleSelectionDelegate {
    
    func singleSelectionItemWillSelect(_ singleSelection: SingleSelection, item: SingleSelectionItem) -> Bool {
        true
    }
    
    func singleSelectionItemDidSelect(_ singleSelection: SingleSelection, item: SingleSelectionItem) {
        selectedChartHours = ChartHours(rawValue: item.id) ?? ChartHours.h6
        glucoseChart.chartHours = selectedChartHours
    }
}

extension ChartDetailsViewController: DatePickerSheetContentDelegate {
    
    func datePickerSheetContent(_ sheetContent: DatePickerSheetContent, didSelect date: Date) {
        // double check to avoid selecting a date in future
        guard date < Date() else {
            return
        }
        
        sheetContent.sheet?.dismissView()
        presenter.loadData(date: date)
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

fileprivate class StatisticsSheetContent: SlideInSheetContent {
        
    private let statistics: StatisticsManager.Statistics
    private let date: Date
    
    init(statistics: StatisticsManager.Statistics, date: Date) {
        self.statistics = statistics
        self.date = date
        super.init(frame: .zero)
        initialize()
    }
    
    required init?(coder: NSCoder) {
        fatalError("Not supported")
    }
    
    private func initialize() {
        backgroundColor = ConstantsUI.mainBackgroundColor
        
        let statisticsView = StatisticsView()
        addSubview(statisticsView)
        
        snp.makeConstraints { make in
            make.width.equalTo(400)
        }
        
        statisticsView.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview()
            make.height.equalTo(250)
            make.centerY.equalToSuperview()
        }
        
        statisticsView.show(statistics: statistics, of: date)
    }
}
