//
//  DailyTrendViewController.swift
//  xdrip
//
//  Created by Yuanbin Cai on 2022/1/10.
//  Copyright © 2022 zDrip. All rights reserved.
//

import UIKit
import Charts
import FSCalendar

class DailyTrendViewController: UIViewController {

    private static let log = Log(type: DailyTrendViewController.self)

    @IBOutlet weak var titleBar: UIView!
    @IBOutlet weak var chartCard: UIView!
    @IBOutlet weak var bgTimeLabel: UILabel!
    @IBOutlet weak var bgValueLabel: UILabel!

    @IBOutlet weak var glucoseChart: GlucoseChart!
    
    private var presenter: DailyTrendP!
    
    private var selectedChartDaysId = ChartDays.Day7
    private var showingDate: Date?

    private lazy var exitButton: UIButton = {
        let view = UIButton()
        view.setImage(R.image.ic_to_portrait(), for: .normal)
        return view
    }()

    private lazy var calendarTitle: CalendarTitle = {
        let calendarTitle = CalendarTitle()
        return calendarTitle
    }()

    private lazy var daysSelection: SingleSelection = {
        let singleSelection = SingleSelection()
        return singleSelection
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        
        instancePresenter()
        
        setupView()
        
        presenter.loadData(of: Date(), withDays: selectedChartDaysId)
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
        presenter = DailyTrendPresenter(view: self)
    }
    
    private func setupView() {
        titleBar.addSubview(exitButton)
        titleBar.addSubview(calendarTitle)
        titleBar.addSubview(daysSelection)
        
        exitButton.snp.makeConstraints { make in
            make.centerY.equalToSuperview()
            make.leading.equalToSuperview().offset(20)
        }
        
        calendarTitle.snp.makeConstraints { make in
            make.centerY.equalToSuperview()
            make.leading.equalTo(exitButton.snp.trailing).offset(20)
        }
        
        daysSelection.snp.makeConstraints { make in
            make.centerY.equalToSuperview()
            make.trailing.equalToSuperview().offset(-10)
            make.height.equalToSuperview()
        }
        
        exitButton.addTarget(self, action: #selector(exitButtonDidClick(_:)), for: .touchUpInside)
        calendarTitle.delegate = self

        var selectionItems = [SingleSelectionItem]()
        selectionItems.append(SingleSelectionItem(id: ChartDays.Day7, title: "7D"))
        selectionItems.append(SingleSelectionItem(id: ChartDays.Day14, title: "14D"))
        selectionItems.append(SingleSelectionItem(id: ChartDays.Day30, title: "30D"))
        selectionItems.append(SingleSelectionItem(id: ChartDays.Day90, title: "90D"))

        daysSelection.show(items: selectionItems)
        daysSelection.delegate = self
        daysSelection.select(id: selectedChartDaysId, triggerCallback: false)
        
        setupChart()
    }

    private func setupChart() {
        glucoseChart.delegate = self
        glucoseChart.dragEnabled = true
        glucoseChart.highlightEnabled = true
        glucoseChart.dateFormat = "HH:mm"
        glucoseChart.chartHours = ChartHours.H24
    }

    @objc private func exitButtonDidClick(_ button: UIButton) {
        dismiss(animated: false)
    }
}

extension DailyTrendViewController: DailyTrendV {

}

extension DailyTrendViewController: GlucoseChartDelegate {

    func chartReadingSelected(_ glucoseChart: GlucoseChart, reading: BgReading) {
//        let dateFormatter = DateFormatter()
//        dateFormatter.dateFormat = "HH:mm"
//        let timestamp = dateFormatter.string(from: reading.timeStamp)
//
//        let showMgDl = UserDefaults.standard.bloodGlucoseUnitIsMgDl
//        DailyTrendViewController.log.d("==> chartValueSelected, (\(timestamp), \(reading.calculatedValue.mgdlToMmol(mgdl: showMgDl)))")
//
//        bgTimeLabel.text = timestamp
//        bgValueLabel.text = reading.calculatedValue.mgdlToMmolAndToString(mgdl: showMgDl)
//
//        let urgentHighInMg = UserDefaults.standard.urgentHighMarkValue
//        let highInMg = UserDefaults.standard.highMarkValue
//        let lowInMg = UserDefaults.standard.lowMarkValue
//        let urgentLowInMg = UserDefaults.standard.urgentLowMarkValue
//
//        if reading.calculatedValue >= urgentHighInMg || reading.calculatedValue <= urgentLowInMg {
//            bgValueLabel.textColor = ConstantsGlucoseChart.glucoseUrgentRangeColor
//
//        } else if reading.calculatedValue >= highInMg || reading.calculatedValue <= lowInMg {
//            bgValueLabel.textColor = ConstantsGlucoseChart.glucoseNotUrgentRangeColor
//
//        } else {
//            bgValueLabel.textColor = ConstantsGlucoseChart.glucoseInRangeColor
//        }
    }

    func chartReadingNothingSelected(_ glucoseChart: GlucoseChart) {
        bgTimeLabel.text = "--:--"
        bgValueLabel.text = "---"
        bgValueLabel.textColor = .white
    }
}

extension DailyTrendViewController: CalendarTitleDelegate {

    func calendarLeftButtonDidClick(_ calendarTitle: CalendarTitle, currentTime: Date) {
        if let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: currentTime) {
            presenter.loadData(of: yesterday, withDays: selectedChartDaysId)
        }
    }

    func calendarRightButtonDidClick(_ calendarTitle: CalendarTitle, currentTime: Date) {
        if let nextDay = Calendar.current.date(byAdding: .day, value: 1, to: currentTime) {
            presenter.loadData(of: nextDay, withDays: selectedChartDaysId)
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

extension DailyTrendViewController: SingleSelectionDelegate {

    func singleSelectionItemWillSelect(_ singleSelection: SingleSelection, item: SingleSelectionItem) -> Bool {
        true
    }

    func singleSelectionItemDidSelect(_ singleSelection: SingleSelection, item: SingleSelectionItem) {
        selectedChartDaysId = item.id
        if let showingDate = showingDate {
            presenter.loadData(of: showingDate, withDays: selectedChartDaysId)
        }
    }
}

extension DailyTrendViewController: DatePickerSheetContentDelegate {

    func datePickerSheetContent(_ sheetContent: DatePickerSheetContent, didSelect date: Date) {
        // double check to avoid selecting a date in future
        guard date < Date() else {
            return
        }

        sheetContent.sheet?.dismissView()
        presenter.loadData(of: date, withDays: selectedChartDaysId)
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

