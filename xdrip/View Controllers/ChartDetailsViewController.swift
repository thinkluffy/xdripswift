//
//  ChartDetailsViewController.swift
//  xdrip
//
//  Created by Yuanbin Cai on 2021/11/9.
//  Copyright © 2021 Johan Degraeve. All rights reserved.
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

    @IBOutlet weak var chartView: ScatterChartView!

    private var presenter: ChartDetailsP!
    
    private var selectedChartHoursId = ChartHours.H6
    
    private lazy var exitButton: UIButton = {
        let view = UIButton()
        view.setImage(R.image.ic_to_portrait(), for: .normal)
        return view
    }()
    
    private lazy var calendarTitle: CalendarTitle = {
        let calendarTitle = CalendarTitle()
        return calendarTitle
    }()
    
    private lazy var chartHoursSelection: SingleSelection = {
        let singleSelection = SingleSelection()
        return singleSelection
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
        selectionItems.append(SingleSelectionItem(id: ChartHours.H1, title: "1H"))
        selectionItems.append(SingleSelectionItem(id: ChartHours.H3, title: "3H"))
        selectionItems.append(SingleSelectionItem(id: ChartHours.H6, title: "6H"))
        selectionItems.append(SingleSelectionItem(id: ChartHours.H12, title: "12H"))
        selectionItems.append(SingleSelectionItem(id: ChartHours.H24, title: "24H"))

        chartHoursSelection.show(items: selectionItems)
        chartHoursSelection.delegate = self
        chartHoursSelection.select(id: selectedChartHoursId, triggerCallback: false)

        showStatisticsButton.onTap { [unowned self] btn in
            if let date = self.calendarTitle.dateTime {
                self.presenter.loadStatistics(date: date)
            }
        }
        
        lockMoveButton.onTap { [unowned self] btn in
            if self.chartView.dragMoveHighlightFirst {
                btn.setImage(R.image.ic_pushpin_unlock(), for: .normal)
                btn.tintColor = .white
                self.chartView.dragMoveHighlightFirst = false

            } else {
                btn.setImage(R.image.ic_pushpin_lock()?.withRenderingMode(.alwaysTemplate), for: .normal)
                btn.tintColor = ConstantsUI.accentRed
                self.chartView.dragMoveHighlightFirst = true
            }
        }
        
        setupChart()
    }
    
    private func setupChart() {
        chartView.delegate = self

        chartView.dragEnabled = true
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
        if selectedChartHoursId == ChartHours.H24 {
            xAxis.granularity = Date.hourInSeconds * 3 // 2 hours do not work, why?
            
        } else {
            xAxis.granularity = Date.hourInSeconds
        }
        xAxis.labelCount = 13 // make the x labels step by 1 hour, do not know why
        
        chartView.leftAxis.enabled = false

        // leave space for limit labels outside viewport
        chartView.setExtraOffsets(left: 0, top: 0, right: 30, bottom: 0)
        
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
        urgentHighLine.labelPosition = .right
        urgentHighLine.valueFont = .systemFont(ofSize: 12)
        urgentHighLine.lineColor = .gray
        urgentHighLine.valueTextColor = .white
        
        let highLine = ChartLimitLine(limit: high, label: high.bgValuetoString(mgdl: showAsMg))
        highLine.lineWidth = 1
        highLine.lineDashLengths = [5, 5]
        highLine.labelPosition = .right
        highLine.valueFont = .boldSystemFont(ofSize: 14)
        highLine.lineColor = .gray
        highLine.valueTextColor = .white
        
        let lowLine = ChartLimitLine(limit: low, label: low.bgValuetoString(mgdl: showAsMg))
        lowLine.lineWidth = 1
        lowLine.lineDashLengths = [5, 5]
        lowLine.labelPosition = .right
        lowLine.valueFont = .boldSystemFont(ofSize: 14)
        lowLine.lineColor = .gray
        lowLine.valueTextColor = .white
        
        let rangeTopLine = ChartLimitLine(limit: yAxis.axisMaximum,
                                          label: yAxis.axisMaximum.bgValuetoString(mgdl: showAsMg))
        rangeTopLine.lineWidth = 2
        rangeTopLine.lineColor = ConstantsUI.mainBackgroundColor
        rangeTopLine.labelPosition = .right
        rangeTopLine.valueFont = .systemFont(ofSize: 12)
        rangeTopLine.valueTextColor = .gray

        let rangeBottomLine = ChartLimitLine(limit: yAxis.axisMinimum,
                                             label: yAxis.axisMinimum.bgValuetoString(mgdl: showAsMg))
        rangeBottomLine.lineWidth = 0
        rangeBottomLine.lineColor = ConstantsUI.mainBackgroundColor
        rangeBottomLine.labelPosition = .right
        rangeBottomLine.valueFont = .systemFont(ofSize: 12)
        rangeBottomLine.valueTextColor = .gray
        
        yAxis.removeAllLimitLines()
        yAxis.addLimitLine(urgentHighLine)
        yAxis.addLimitLine(highLine)
        yAxis.addLimitLine(lowLine)
        yAxis.addLimitLine(rangeTopLine)
        yAxis.addLimitLine(rangeBottomLine)
        
        yAxis.drawLimitLinesBehindDataEnabled = true
    }
    
    @objc private func exitButtonDidClick(_ button: UIButton) {
        dismiss(animated: false)
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
}

extension ChartDetailsViewController: ChartDetailsV {
    
    func show(readings: [BgReading]?, from fromDate: Date, to toDate: Date) {
        // setup calendar title
        calendarTitle.dateTime = fromDate
        let isToday = Calendar.current.isDateInToday(fromDate)
        calendarTitle.showRightArrow = !isToday
        
        // reset selected bg time and value
        chartView.highlightValues(nil)
        bgTimeLabel.text = "--:--"
        bgValueLabel.text = "---"
        bgValueLabel.textColor = .white
        
        // setup chart
        let showAsMg = UserDefaults.standard.bloodGlucoseUnitIsMgDl
        
        let urgentHighInMg = UserDefaults.standard.urgentHighMarkValue
        let highInMg = UserDefaults.standard.highMarkValue
        let lowInMg = UserDefaults.standard.lowMarkValue
        let urgentLowInMg = UserDefaults.standard.urgentLowMarkValue
        
        guard let readings = readings, !readings.isEmpty else {
            ChartDetailsViewController.log.i("reading is nil, nothing to show")
            
            // put a placeholder to avoid showing default No Data view
            var placeholderEntries = [ChartDataEntry]()
            let placeholdeEntry = ChartDataEntry(x: fromDate.timeIntervalSince1970, y: highInMg.mgdlToMmol(mgdl: showAsMg))
            placeholderEntries.append(placeholdeEntry)
            let placeholderDataSet = ScatterChartDataSet(entries: placeholderEntries)
            placeholderDataSet.setColor(.clear)
            
            let data = ScatterChartData(dataSets: [
                placeholderDataSet
            ])
            chartView.data = data
            return
        }
        
        var urgentHighValues = [ChartDataEntry]()
        var highValues = [ChartDataEntry]()
        var inRangeValues = [ChartDataEntry]()
        var lowValues = [ChartDataEntry]()
        var urgentLowValues = [ChartDataEntry]()

        let filteredReadings = filterReadingsIfNeeded(readings)

        for r in filteredReadings {
            let bgValue = showAsMg ? r.calculatedValue : r.calculatedValue.mgdlToMmol()
            let chartDataEntry = ChartDataEntry(x: r.timeStamp.timeIntervalSince1970, y: bgValue)
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
        urgentHighDataSet.setColor(ConstantsGlucoseChart.glucoseUrgentRangeColor)
        
        let highDataSet = ScatterChartDataSet(entries: highValues)
        highDataSet.setColor(ConstantsGlucoseChart.glucoseNotUrgentRangeColor)
        
        let inRangeDataSet = ScatterChartDataSet(entries: inRangeValues)
        inRangeDataSet.setColor(ConstantsGlucoseChart.glucoseInRangeColor)
        
        let lowDataSet = ScatterChartDataSet(entries: lowValues)
        lowDataSet.setColor(ConstantsGlucoseChart.glucoseNotUrgentRangeColor)
        
        let urgentLowDataSet = ScatterChartDataSet(entries: urgentLowValues)
        urgentLowDataSet.setColor(ConstantsGlucoseChart.glucoseUrgentRangeColor)
        
        chartView.xAxis.axisMinimum = fromDate.timeIntervalSince1970
        chartView.xAxis.axisMaximum = toDate.timeIntervalSince1970
        
        let data = ScatterChartData(dataSets: [
            urgentHighDataSet,
            highDataSet,
            inRangeDataSet,
            lowDataSet,
            urgentLowDataSet
        ])
        
        for s in data.dataSets {
            guard let scatterDataSet = s as? ScatterChartDataSet else {
                continue
            }
            applyDataSetStyle(dataSet: scatterDataSet)
            applyDataShapeSize(dataSet: scatterDataSet)
        }
        chartView.data = data
        
        let xRange = calChartHoursSeconds(chartHoursId: selectedChartHoursId)
        chartView.setVisibleXRange(minXRange: xRange, maxXRange: xRange)

        // move current time to centerX
        if isToday && showingDate == nil {
            chartView.moveViewToX(Date().timeIntervalSince1970 - xRange/2)
        }

        showingDate = fromDate
    }
    
    func show(statistics: StatisticsManager.Statistics, of date: Date) {
        let sheet = HorizontalSheet()
        let content = StatisticsSheetContent(statistics: statistics, date: date)
        sheet.contentView = content
        sheet.show(in: view, dimColor: .black.withAlphaComponent(0.5))
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
            xRange = Date.hourInSeconds * 6
        }
        return xRange
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

extension ChartDetailsViewController: ChartViewDelegate {
    
    @objc func chartValueSelected(_ chartView: ChartViewBase, entry: ChartDataEntry, highlight: Highlight) {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "HH:mm"
        let timestamp = dateFormatter.string(from: Date(timeIntervalSince1970: entry.x))
        ChartDetailsViewController.log.d("==> chartValueSelected, (\(timestamp), \(entry.y))")
                
        bgTimeLabel.text = timestamp
        bgValueLabel.text = entry.y.bgValuetoString(mgdl: UserDefaults.standard.bloodGlucoseUnitIsMgDl)
        
        let showAsMg = UserDefaults.standard.bloodGlucoseUnitIsMgDl
        
        let urgentHighInMg = UserDefaults.standard.urgentHighMarkValue.mgdlToMmol(mgdl: showAsMg)
        let highInMg = UserDefaults.standard.highMarkValue.mgdlToMmol(mgdl: showAsMg)
        let lowInMg = UserDefaults.standard.lowMarkValue.mgdlToMmol(mgdl: showAsMg)
        let urgentLowInMg = UserDefaults.standard.urgentLowMarkValue.mgdlToMmol(mgdl: showAsMg)
        
        if entry.y >= urgentHighInMg || entry.y <= urgentLowInMg {
            bgValueLabel.textColor = ConstantsGlucoseChart.glucoseUrgentRangeColor

        } else if entry.y >= highInMg || entry.y <= lowInMg {
            bgValueLabel.textColor = ConstantsGlucoseChart.glucoseNotUrgentRangeColor

        } else {
            bgValueLabel.textColor = ConstantsGlucoseChart.glucoseInRangeColor
        }
    }
    
    @objc func chartValueNothingSelected(_ chartView: ChartViewBase) {
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
        
        let sheet = HorizontalSheet()
        let content = DatePickerSheetContent(selectedDate: selectedDate)
        content.delegate = self
        sheet.contentView = content
        sheet.show(in: view, dimColor: .black.withAlphaComponent(0.5))
    }
}

extension ChartDetailsViewController: SingleSelectionDelegate {
    
    func singleSelectionItemWillSelect(_ singleSelecton: SingleSelection, item: SingleSelectionItem) -> Bool {
        return true
    }
    
    func singleSelectionItemDidSelect(_ singleSelecton: SingleSelection, item: SingleSelectionItem) {
        selectedChartHoursId = item.id
        
        let centerVisibleX = (chartView.highestVisibleX - chartView.lowestVisibleX) / 2 + chartView.lowestVisibleX

        let xRange = calChartHoursSeconds(chartHoursId: selectedChartHoursId)
        chartView.setVisibleXRange(minXRange: xRange, maxXRange: xRange)
        
        if selectedChartHoursId == ChartHours.H24 {
            chartView.xAxis.granularity = Date.hourInSeconds * 3 // 2 hours do not work, why?
            
        } else {
            chartView.xAxis.granularity = Date.hourInSeconds
        }
        chartView.notifyDataSetChanged()
        
        // keep center still center
        chartView.moveViewToX(centerVisibleX - xRange / 2)
    }
}

extension ChartDetailsViewController: DatePickerSheetContentDelegate {
    
    fileprivate func datePickerSheetContent(_ sheetContent: DatePickerSheetContent, didSelect date: Date) {
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

fileprivate protocol DatePickerSheetContentDelegate: AnyObject {
    
    func datePickerSheetContent(_ sheetContent: DatePickerSheetContent, didSelect date: Date)
}

fileprivate class DatePickerSheetContent: HorizontalSheetContent {
    
    weak var delegate: DatePickerSheetContentDelegate?
        
    private let selectedDate: Date?
    
    init(selectedDate: Date) {
        self.selectedDate = selectedDate
        super.init(frame: .zero)
        initialize()
    }
    
    required init?(coder: NSCoder) {
        selectedDate = nil
        super.init(coder: coder)
        initialize()
    }
    
    private func initialize() {
        backgroundColor = .clear
        
        let container = UIView()
        container.backgroundColor = ConstantsUI.mainBackgroundColor
        
        addSubview(container)

        let calendar = FSCalendar()
        calendar.appearance.headerTitleColor = .white
        calendar.appearance.headerDateFormat = "yyyy-MM"
        calendar.appearance.headerMinimumDissolvedAlpha = 0
        calendar.appearance.titleDefaultColor = .white
        calendar.appearance.weekdayTextColor = .white
        calendar.appearance.todayColor = ConstantsUI.contentBackgroundColor
        calendar.appearance.todaySelectionColor = ConstantsUI.accentRed
        calendar.appearance.selectionColor = ConstantsUI.accentRed
        
        if let selectedDate = selectedDate {
            calendar.select(selectedDate)
        }
            
        calendar.delegate = self
        
        container.addSubview(calendar)

        container.snp.makeConstraints { make in
            make.width.equalTo(320)
            make.edges.equalToSuperview()
        }
        
        calendar.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(10)
        }
    }
}

extension DatePickerSheetContent: FSCalendarDelegate {
    
    // avoid selecting a date in future
    func calendar(_ calendar: FSCalendar, shouldSelect date: Date, at monthPosition: FSCalendarMonthPosition) -> Bool {
        date <= Date()
    }
    
    func calendar(_ calendar: FSCalendar, didSelect date: Date, at monthPosition: FSCalendarMonthPosition) {
        delegate?.datePickerSheetContent(self, didSelect: date)
    }
}

fileprivate class StatisticsSheetContent: HorizontalSheetContent {
        
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
        backgroundColor = .clear
        
        let container = UIView()
        container.backgroundColor = ConstantsUI.mainBackgroundColor
        
        addSubview(container)

        let statisticsView = StatisticsView()
        
        container.addSubview(statisticsView)

        container.snp.makeConstraints { make in
            make.width.equalTo(400)
            make.edges.equalToSuperview()
        }
        
        statisticsView.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview()
            make.height.equalTo(250)
            make.centerY.equalToSuperview()
        }
        
        statisticsView.show(statistics: statistics, of: date)
    }
}
