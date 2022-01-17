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
    
    @IBOutlet weak var timeLabel: UILabel!

    @IBOutlet weak var decileTitleLabel: UILabel!
    @IBOutlet weak var quartileTitleLabel: UILabel!
    @IBOutlet weak var medianTitleLabel: UILabel!
    @IBOutlet weak var seventyFifthPercentileTitleLabel: UILabel!
    @IBOutlet weak var ninetyPercentileTitleLabel: UILabel!

    @IBOutlet weak var decileLabel: UILabel!
    @IBOutlet weak var quartileLabel: UILabel!
    @IBOutlet weak var medianLabel: UILabel!
    @IBOutlet weak var seventyFifthPercentileLabel: UILabel!
    @IBOutlet weak var ninetyPercentileLabel: UILabel!

    @IBOutlet weak var statusLabel: UILabel!
    @IBOutlet weak var loadingIndicatorView: UIActivityIndicatorView!
    @IBOutlet weak var dailyTrendChart: DailyTrendChart!

    private var presenter: DailyTrendP!

    private var selectedChartDays = ChartDays.day7
    private var showingDate: Date?

    private lazy var exitButton: UIButton = {
        let view = UIButton()
        view.setImage(R.image.ic_to_portrait(), for: .normal)
        return view
    }()

    private lazy var calendarTitle: CalendarTitle = {
        CalendarTitle()
    }()

    private lazy var daysSelection: SingleSelection = {
        SingleSelection()
    }()

    override func viewDidLoad() {
        super.viewDidLoad()

        instancePresenter()

        setupView()

        presenter.loadData(of: Date(), withDays: selectedChartDays.rawValue)
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
        selectionItems.append(SingleSelectionItem(id: ChartDays.day7.rawValue, title: "7D"))
        selectionItems.append(SingleSelectionItem(id: ChartDays.day14.rawValue, title: "14D"))
        selectionItems.append(SingleSelectionItem(id: ChartDays.day30.rawValue, title: "30D"))
        selectionItems.append(SingleSelectionItem(id: ChartDays.day90.rawValue, title: "90D"))

        daysSelection.show(items: selectionItems)
        daysSelection.delegate = self
        daysSelection.select(id: selectedChartDays.rawValue, triggerCallback: false)

        decileTitleLabel.text = R.string.common.decile()
        quartileTitleLabel.text = R.string.common.quartile()
        medianTitleLabel.text = R.string.common.median()
        seventyFifthPercentileTitleLabel.text = R.string.common.seventyFifthPercentile()
        ninetyPercentileTitleLabel.text = R.string.common.ninetyPercentile()

        let valueLabelFont = UIFont.monospacedDigitSystemFont(ofSize: 14, weight: .light)
        decileLabel.font = valueLabelFont
        quartileLabel.font = valueLabelFont
        seventyFifthPercentileLabel.font = valueLabelFont
        ninetyPercentileLabel.font = valueLabelFont

        medianLabel.font = .monospacedDigitSystemFont(ofSize: 14, weight: .heavy)

        let chartCardTapGesture = UITapGestureRecognizer { [unowned self] _ in
            dailyTrendChart.unHighlightAll()
        }
        chartCard.addGestureRecognizer(chartCardTapGesture)

        setupChart()
    }

    private func setupChart() {
        dailyTrendChart.delegate = self
        dailyTrendChart.dragEnabled = true
        dailyTrendChart.highlightEnabled = true
        dailyTrendChart.dateFormat = "HH:mm"
    }

    @objc private func exitButtonDidClick(_ button: UIButton) {
        dismiss(animated: false)
    }

    private func resetValueLabels() {
        decileLabel.text = "---"
        decileLabel.textColor = .systemGray

        quartileLabel.text = "---"
        quartileLabel.textColor = .systemGray

        medianLabel.text = "---"
        medianLabel.textColor = .systemGray

        seventyFifthPercentileLabel.text = "---"
        seventyFifthPercentileLabel.textColor = .systemGray

        ninetyPercentileLabel.text = "---"
        ninetyPercentileLabel.textColor = .systemGray
    }
}

extension DailyTrendViewController: DailyTrendV {

    func showLoadingData() {
        statusLabel.text = R.string.common.loading()
        statusLabel.textColor = .white

        loadingIndicatorView.isHidden = false
        loadingIndicatorView.startAnimating()
        
        calendarTitle.isUserInteractionEnabled = false
        daysSelection.isUserInteractionEnabled = false
    }

    func showNoEnoughData(ofDate date: Date) {
        DailyTrendViewController.log.d("==> showNoEnoughData")

        statusLabel.text = R.string.common.not_enough_data()
        statusLabel.textColor = .white

        loadingIndicatorView.stopAnimating()
        loadingIndicatorView.isHidden = true
        
        calendarTitle.isUserInteractionEnabled = true
        daysSelection.isUserInteractionEnabled = true
        
        // setup calendar title
        calendarTitle.dateTime = date
        let isToday = Calendar.current.isDateInToday(date)
        calendarTitle.showRightArrow = !isToday

        // reset selected bg time and value
        dailyTrendChart.unHighlightAll()
        timeLabel.text = "--:--"

        resetValueLabels()

        showingDate = date

        dailyTrendChart.showNoData()
    }

    func showDailyTrend(ofDate date: Date,
						withDays daysRange: Int,
						validDays validDays: Double,
						dailyTrendItems: [DailyTrend.DailyTrendItem]) {
        DailyTrendViewController.log.d("==> showDailyTrend, daysRange: \(daysRange), validDays: \(validDays), items: \(dailyTrendItems.count)")

        statusLabel.text = R.string.dailyTrend.daily_trend_available_days(validDays, daysRange)
		statusLabel.textColor = Int(validDays.rounded()) < daysRange ?  ConstantsUI.warningColor : .white

        loadingIndicatorView.stopAnimating()
        loadingIndicatorView.isHidden = true
        
        calendarTitle.isUserInteractionEnabled = true
        daysSelection.isUserInteractionEnabled = true
        
        // setup calendar title
        calendarTitle.dateTime = date
        let isToday = Calendar.current.isDateInToday(date)
        calendarTitle.showRightArrow = !isToday

        // reset selected bg time and value
        dailyTrendChart.unHighlightAll()
        timeLabel.text = "--:--"

        resetValueLabels()

        showingDate = date

        dailyTrendChart.show(dailyTrendItems: dailyTrendItems)
    }
}

extension DailyTrendViewController: DailyTrendChartDelegate {

    func dailyTrendChartItemSelected(_ chart: DailyTrendChart, item: DailyTrend.DailyTrendItem) {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "HH:mm"
        dateFormatter.timeZone = TimeZone(secondsFromGMT: 0)
        let timestamp = dateFormatter.string(from: Date(timeIntervalSince1970: item.timeInterval))

        if item.isValid {
            let showMgDl = UserDefaults.standard.bloodGlucoseUnitIsMgDl

            timeLabel.text = timestamp

            let urgentHighInMg = UserDefaults.standard.urgentHighMarkValue
            let highInMg = UserDefaults.standard.highMarkValue
            let lowInMg = UserDefaults.standard.lowMarkValue
            let urgentLowInMg = UserDefaults.standard.urgentLowMarkValue

            decileLabel.text = item.high!.mgdlToMmolAndToString(mgdl: showMgDl, withUnit: true)
            quartileLabel.text = item.medianHigh!.mgdlToMmolAndToString(mgdl: showMgDl, withUnit: true)
            medianLabel.text = item.median!.mgdlToMmolAndToString(mgdl: showMgDl, withUnit: true)
            seventyFifthPercentileLabel.text = item.medianLow!.mgdlToMmolAndToString(mgdl: showMgDl, withUnit: true)
            ninetyPercentileLabel.text = item.low!.mgdlToMmolAndToString(mgdl: showMgDl, withUnit: true)

            func colorOfBg(_ bgInMg: Double) -> UIColor {
                if bgInMg >= urgentHighInMg || bgInMg <= urgentLowInMg {
                    return ConstantsGlucoseChart.glucoseUrgentRangeColor

                } else if bgInMg >= highInMg || bgInMg <= lowInMg {
                    return ConstantsGlucoseChart.glucoseNotUrgentRangeColor

                } else {
                    return ConstantsGlucoseChart.glucoseInRangeColor
                }
            }

            decileLabel.textColor = colorOfBg(item.high!)
            quartileLabel.textColor = colorOfBg(item.medianHigh!)
            medianLabel.textColor = colorOfBg(item.median!)
            seventyFifthPercentileLabel.textColor = colorOfBg(item.medianLow!)
            ninetyPercentileLabel.textColor = colorOfBg(item.low!)

        } else {
            timeLabel.text = "--:--"
            resetValueLabels()
        }
    }

    func dailyTrendChartItemNothingSelected(_ chart: DailyTrendChart) {
        timeLabel.text = "--:--"

        resetValueLabels()
    }
}

extension DailyTrendViewController: CalendarTitleDelegate {

    func calendarLeftButtonDidClick(_ calendarTitle: CalendarTitle, currentTime: Date) {
        if let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: currentTime) {
            presenter.loadData(of: yesterday, withDays: selectedChartDays.rawValue)
        }
    }

    func calendarRightButtonDidClick(_ calendarTitle: CalendarTitle, currentTime: Date) {
        if let nextDay = Calendar.current.date(byAdding: .day, value: 1, to: currentTime) {
            presenter.loadData(of: nextDay, withDays: selectedChartDays.rawValue)
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
        guard let chartDays = ChartDays(rawValue: item.id) else {
            return
        }

        selectedChartDays = chartDays
        if let showingDate = showingDate {
            presenter.loadData(of: showingDate, withDays: selectedChartDays.rawValue)
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
        presenter.loadData(of: date, withDays: selectedChartDays.rawValue)
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

