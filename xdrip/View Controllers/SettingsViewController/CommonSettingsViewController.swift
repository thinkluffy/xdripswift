//
//  CommonSettingsViewController.swift
//  xdrip
//
//  Created by Yuanbin Cai on 2021/12/12.
//  Copyright © 2021 Johan Degraeve. All rights reserved.
//

import UIKit
import PopupDialog

class CommonSettingsViewController: SubSettingsViewController {

    private lazy var tableView: UITableView = {
        let tableView = UITableView(frame: .zero, style: .insetGrouped)
        tableView.backgroundColor = ConstantsUI.mainBackgroundColor
        tableView.showsVerticalScrollIndicator = false
        return tableView
    }()
    
    private var tableData: TableData!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        title = R.string.settingsViews.commonSettings()
        
        setupView()
        
        buildData()
    }
    
    private func setupView() {
        view.backgroundColor = ConstantsUI.mainBackgroundColor
        
        view.addSubview(tableView)
        
        tableView.snp.makeConstraints { make in
            make.edges.equalTo(view.safeAreaLayoutGuide)
        }
    }
    
    private func buildData() {
        var tableDataBuilder = TableDataBuilder()
            .configure(titleTextColor: ConstantsUI.tableTitleColor,
                       detailTextColor: ConstantsUI.tableDetailTextColor,
                       sectionHeaderColor: ConstantsUI.tableViewHeaderTextColor)
            
        tableDataBuilder = buildDataOfGeneral(builder: tableDataBuilder)
        tableDataBuilder = buildDataOfHomeScreen(builder: tableDataBuilder)
        tableDataBuilder = buildDataOfStatistics(builder: tableDataBuilder)
        tableDataBuilder = buildDataOfMore(builder: tableDataBuilder)

        tableData = tableDataBuilder.build()
        
        tableView.delegate = tableData
        tableView.dataSource = tableData
    }
    
    private func buildDataOfGeneral(builder: TableDataBuilder) -> TableDataBuilder {
        return builder
            .section(headerTitle: R.string.settingsViews.settingsviews_sectiontitlegeneral())
            .toggleCell(title: R.string.settingsViews.settingsviews_showReadingInNotification(),
                        isOn: UserDefaults.standard.showReadingInNotification, toggleDidChange: { from, to in
                UserDefaults.standard.showReadingInNotification = to
            })
            .operationCell(title: R.string.settingsViews.settingsviews_IntervalTitle(),
                           detailedText: R.string.common.howManyMinutes(UserDefaults.standard.notificationInterval),
                           didClick: {
                [unowned self] operationCell, tableView, indexPath in
                
                var data = [String]()
                for i in 1 ... 30 {
                    data.append(R.string.common.howManyMinutes(i))
                }
                let selectedRow = UserDefaults.standard.notificationInterval - 1
                
                let pickerViewData = PickerViewDataBuilder(
                    data: data) {
                        index, _ in
                        if index != selectedRow {
                            UserDefaults.standard.notificationInterval = index + 1
                            operationCell.detailedText = R.string.common.howManyMinutes(index + 1)
                            tableView.reloadRows(at: [indexPath], with: .none)
                        }
                    }
                    .title(Texts_SettingsView.settingsviews_IntervalTitle)
                    .subTitle(Texts_SettingsView.settingsviews_IntervalMessage)
                    .selectedRow(selectedRow)
                    .build()
                
                _ = BottomSheetPickerViewController.show(in: self, pickerViewData: pickerViewData)
                
            })
            .toggleCell(title: R.string.settingsViews.settingsviews_labelShowReadingInAppBadge(),
                        isOn: UserDefaults.standard.showReadingInAppBadge, toggleDidChange: { from, to in
                UserDefaults.standard.showReadingInAppBadge = to
            })
    }
    
    private func bgPickerData(biggest: Double, smallest: Double, dataBefore: Double) -> ([String], Int) {
        let isMg = UserDefaults.standard.bloodGlucoseUnitIsMgDl

        var data = [String]()
        let biggestInUnit: Double
        let smallestInUnit: Double
        let dataStringBefore = dataBefore.mgdlToMmol(mgdl: isMg).bgValuetoString(mgdl: isMg)

        if isMg {
            biggestInUnit = biggest.rounded() - 1
            smallestInUnit = smallest.rounded() + 1
            
        } else {
            biggestInUnit = Double(biggest.mgdlToMmolAndToString(mgdl: isMg))! - 0.1
            smallestInUnit = Double(smallest.mgdlToMmolAndToString(mgdl: isMg))! + 0.1
        }
        
        var selectedRow = 0
        var rowCount = 0
        
        stride(from: biggestInUnit, through: smallestInUnit, by: isMg ? -1 : -0.1).forEach { i in
            data.append(i.bgValuetoString(mgdl: isMg))
            if i.bgValuetoString(mgdl: isMg) == dataStringBefore {
                selectedRow = rowCount
            }
            rowCount += 1
        }
        return (data, selectedRow)
    }
    
    private func buildDataOfHomeScreen(builder: TableDataBuilder) -> TableDataBuilder {
        let isMg = UserDefaults.standard.bloodGlucoseUnitIsMgDl
        
        return builder
            .section(headerTitle: R.string.settingsViews.settingsviews_sectiontitlehomescreen())
            .operationCell(title: R.string.settingsViews.settingsviews_urgentHighValue(),
                           detailedText: UserDefaults.standard.urgentHighMarkValueInUserChosenUnit.bgValuetoString(mgdl: isMg),
                           didClick: {
                [unowned self] operationCell, tableView, indexPath in
                
                let (data, selectedRow) = bgPickerData(
                    biggest: UserDefaults.standard.chartHeight,
                    smallest: UserDefaults.standard.highMarkValue,
                    dataBefore: UserDefaults.standard.urgentHighMarkValue
                )
                
                let pickerViewData = PickerViewDataBuilder(
                    data: data) { index, rowData in
                        UserDefaults.standard.urgentHighMarkValueInUserChosenUnitRounded = rowData
                        operationCell.detailedText = UserDefaults.standard.urgentHighMarkValueInUserChosenUnit.bgValuetoString(mgdl: isMg)
                        tableView.reloadRows(at: [indexPath], with: .none)
                    }
                    .title(Texts_SettingsView.labelUrgentHighValue)
                    .selectedRow(selectedRow)
                    .build()
                
                _ = BottomSheetPickerViewController.show(in: self, pickerViewData: pickerViewData)
            })
            .operationCell(title: R.string.settingsViews.settingsviews_highValue(),
                           detailedText: UserDefaults.standard.highMarkValueInUserChosenUnit.bgValuetoString(mgdl: isMg),
                           didClick: {
                [unowned self] operationCell, tableView, indexPath in
                
                let (data, selectedRow) = bgPickerData(
                    biggest: UserDefaults.standard.urgentHighMarkValue,
                    smallest: UserDefaults.standard.lowMarkValue,
                    dataBefore: UserDefaults.standard.highMarkValue
                )
                
                let pickerViewData = PickerViewDataBuilder(
                    data: data) { index, rowData in
                        UserDefaults.standard.highMarkValueInUserChosenUnitRounded = rowData
                        operationCell.detailedText = UserDefaults.standard.highMarkValueInUserChosenUnit.bgValuetoString(mgdl: isMg)
                        tableView.reloadRows(at: [indexPath], with: .none)
                    }
                    .title(Texts_SettingsView.labelHighValue)
                    .selectedRow(selectedRow)
                    .build()
                
                _ = BottomSheetPickerViewController.show(in: self, pickerViewData: pickerViewData)
             })
            .operationCell(title: R.string.settingsViews.settingsviews_lowValue(),
                           detailedText: UserDefaults.standard.lowMarkValueInUserChosenUnit.bgValuetoString(mgdl: isMg),
                           didClick: {
                [unowned self] operationCell, tableView, indexPath in
                
                let (data, selectedRow) = bgPickerData(
                    biggest: UserDefaults.standard.highMarkValue,
                    smallest: UserDefaults.standard.urgentLowMarkValue,
                    dataBefore: UserDefaults.standard.lowMarkValue
                )
                
                let pickerViewData = PickerViewDataBuilder(
                    data: data) { index, rowData in
                        UserDefaults.standard.lowMarkValueInUserChosenUnitRounded = rowData
                        operationCell.detailedText = UserDefaults.standard.lowMarkValueInUserChosenUnit.bgValuetoString(mgdl: isMg)
                        tableView.reloadRows(at: [indexPath], with: .none)
                    }
                    .title(Texts_SettingsView.labelLowValue)
                    .selectedRow(selectedRow)
                    .build()
                
                _ = BottomSheetPickerViewController.show(in: self, pickerViewData: pickerViewData)
             })
            .operationCell(title: R.string.settingsViews.settingsviews_urgentLowValue(),
                           detailedText: UserDefaults.standard.urgentLowMarkValueInUserChosenUnit.bgValuetoString(mgdl: isMg),
                           didClick: {
                [unowned self] operationCell, tableView, indexPath in
                
                let (data, selectedRow) = bgPickerData(
                    biggest: UserDefaults.standard.lowMarkValue,
                    smallest: Constants.minBgMgDl,
                    dataBefore: UserDefaults.standard.urgentLowMarkValue
                )
                
                let pickerViewData = PickerViewDataBuilder(
                    data: data) { index, rowData in
                        UserDefaults.standard.urgentLowMarkValueInUserChosenUnitRounded = rowData
                        operationCell.detailedText = UserDefaults.standard.urgentLowMarkValueInUserChosenUnit.bgValuetoString(mgdl: isMg)
                        tableView.reloadRows(at: [indexPath], with: .none)
                    }
                    .title(Texts_SettingsView.labelUrgentLowValue)
                    .selectedRow(selectedRow)
                    .build()
                
                _ = BottomSheetPickerViewController.show(in: self, pickerViewData: pickerViewData)
             })
            .operationCell(title: R.string.settingsViews.settingsviews_chartHeight(),
                           detailedText: UserDefaults.standard.chartHeight.mgdlToMmolAndToString(mgdl: isMg),
                           didClick: {
                [unowned self] operationCell, tableView, indexPath in
                
                let heights: [Double] = [400, 300, 220]
                var data = [String]()
                var selectedRow: Int?

                for (i, h) in heights.enumerated() {
                    data.append(h.mgdlToMmolAndToString(mgdl: isMg))
                    if UserDefaults.standard.chartHeight == h {
                        selectedRow = i
                    }
                }
                
                let pickerViewData = PickerViewDataBuilder(
                    data: data) {
                        index, _ in
                        
                        guard index != selectedRow else {
                            return
                        }
                        
                        let height = heights[index]
                        if height < UserDefaults.standard.urgentHighMarkValue {
                            self.view.makeToast(R.string.settingsViews.toast_chart_height_smaller_than_urgent_high(),
                                                duration: 4,
                                                position: .bottom)
                            return
                        }
                        
                        UserDefaults.standard.chartHeight = height
                        operationCell.detailedText = height.mgdlToMmolAndToString(mgdl: isMg)
                        tableView.reloadRows(at: [indexPath], with: .none)
                    }
                    .title(R.string.settingsViews.settingsviews_chartHeight())
                    .selectedRow(selectedRow)
                    .build()
                
                _ = BottomSheetPickerViewController.show(in: self, pickerViewData: pickerViewData)
             })
            .toggleCell(title: R.string.settingsViews.settingsviews_chartDots5MinsApart(),
                        isOn: UserDefaults.standard.chartDots5MinsApart,
                        toggleDidChange: {
                from, to in
                UserDefaults.standard.chartDots5MinsApart = to
            })
    }
    
    private func buildDataOfStatistics(builder: TableDataBuilder) -> TableDataBuilder {
        return builder
            .section(headerTitle: R.string.settingsViews.settingsviews_sectiontitlestatistics())
            .toggleCell(title: R.string.settingsViews.settingsviews_useStandardStatisticsRange(),
                        isOn: UserDefaults.standard.useStandardStatisticsRange,
                        toggleDidChange: {
                from, to in
                UserDefaults.standard.useStandardStatisticsRange = to
            })
            .toggleCell(title: R.string.settingsViews.settingsviews_useIFCCA1C(),
                        isOn: UserDefaults.standard.useIFCCA1C,
                        toggleDidChange: {
                from, to in
                UserDefaults.standard.useIFCCA1C = to
            })
    }
    
    private func buildDataOfMore(builder: TableDataBuilder) -> TableDataBuilder {
        return builder
            .section(headerTitle: R.string.settingsViews.sectionTitleMore())
            .operationCell(title: R.string.settingsViews.moreSettings(),
                           accessoryView: DTCustomColoredAccessory(color: ConstantsUI.disclosureIndicatorColor),
                           didClick: {
                [unowned self] operationCell, tableView, indexPath in
                let viewController = MoreSettingsViewController()
                self.navigationController?.pushViewController(viewController, animated: true)
            })
    }
}
