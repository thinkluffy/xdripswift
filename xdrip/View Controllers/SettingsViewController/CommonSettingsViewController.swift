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
                    data: data,
                    actionHandler: {
                        index, _ in
                        if index != selectedRow {
                            UserDefaults.standard.notificationInterval = index + 1
                            operationCell.detailedText = R.string.common.howManyMinutes(index + 1)
                            tableView.reloadRows(at: [indexPath], with: .none)
                        }
                    }
                )
                    .title(Texts_SettingsView.settingsviews_IntervalTitle)
                    .subTitle(Texts_SettingsView.settingsviews_IntervalMessage)
                    .selectedRow(selectedRow)
                    .build()
                
                BottomSheetPickerViewController.show(in: self, pickerViewData: pickerViewData)
                
            })
            .toggleCell(title: R.string.settingsViews.settingsviews_labelShowReadingInAppBadge(),
                        isOn: UserDefaults.standard.showReadingInAppBadge, toggleDidChange: { from, to in
                UserDefaults.standard.showReadingInAppBadge = to
            })
    }
    
    private func buildDataOfHomeScreen(builder: TableDataBuilder) -> TableDataBuilder {
        let isMg = UserDefaults.standard.bloodGlucoseUnitIsMgDl
        
        return builder
            .section(headerTitle: R.string.settingsViews.settingsviews_sectiontitlehomescreen())
            .operationCell(title: R.string.settingsViews.settingsviews_urgentHighValue(),
                           detailedText: UserDefaults.standard.urgentHighMarkValueInUserChosenUnit.bgValuetoString(mgdl: isMg),
                           didClick: {
                [unowned self] operationCell, tableView, indexPath in
                
                let placeHolder = ConstantsBGGraphBuilder.defaultUrgentHighMarkInMgdl
                    .mgdlToMmolAndToString(mgdl: isMg)
                
                let alert = PopupDialog(
                    title: Texts_SettingsView.labelUrgentHighValue,
                    message: nil,
                    keyboardType: isMg ? .numberPad : .decimalPad,
                    text: UserDefaults.standard.urgentHighMarkValueInUserChosenUnitRounded,
                    placeHolder: placeHolder
                ) {
                    urgentHighMarkValue in
                    
                    var input = urgentHighMarkValue
                    if urgentHighMarkValue == "" {
                        input = placeHolder
                    }
                    UserDefaults.standard.urgentHighMarkValueInUserChosenUnitRounded = input
                    operationCell.detailedText = UserDefaults.standard.urgentHighMarkValueInUserChosenUnit.bgValuetoString(mgdl: isMg)
                    tableView.reloadRows(at: [indexPath], with: .none)
                }
                
                self.present(alert, animated: true, completion: nil)
            })
            .operationCell(title: R.string.settingsViews.settingsviews_highValue(),
                           detailedText: UserDefaults.standard.highMarkValueInUserChosenUnit.bgValuetoString(mgdl: isMg),
                           didClick: {
                [unowned self] operationCell, tableView, indexPath in
                
                let placeHolder = ConstantsBGGraphBuilder.defaultHighMarkInMgdl
                    .mgdlToMmolAndToString(mgdl: isMg)
                
                let alert = PopupDialog(
                    title: Texts_SettingsView.labelHighValue,
                    message: nil,
                    keyboardType: isMg ? .numberPad : .decimalPad,
                    text: UserDefaults.standard.highMarkValueInUserChosenUnitRounded,
                    placeHolder: placeHolder
                ) {
                    highMarkValue in
                    
                    var input = highMarkValue
                    if highMarkValue == "" {
                        input = placeHolder
                    }
                    UserDefaults.standard.highMarkValueInUserChosenUnitRounded = input
                    operationCell.detailedText = UserDefaults.standard.highMarkValueInUserChosenUnit.bgValuetoString(mgdl: isMg)
                    tableView.reloadRows(at: [indexPath], with: .none)
                }
                
                self.present(alert, animated: true, completion: nil)
             })
            .operationCell(title: R.string.settingsViews.settingsviews_lowValue(),
                           detailedText: UserDefaults.standard.lowMarkValueInUserChosenUnit.bgValuetoString(mgdl: isMg),
                           didClick: {
                [unowned self] operationCell, tableView, indexPath in
                
                let placeHolder = ConstantsBGGraphBuilder.defaultLowMarkInMgdl
                    .mgdlToMmolAndToString(mgdl: isMg)
                
                let alert = PopupDialog(
                    title: Texts_SettingsView.labelLowValue,
                    message: nil,
                    keyboardType: isMg ? .numberPad : .decimalPad,
                    text: UserDefaults.standard.lowMarkValueInUserChosenUnitRounded,
                    placeHolder: placeHolder
                ) {
                    lowMarkValue in
                    
                    var input = lowMarkValue
                    if lowMarkValue == "" {
                        input = placeHolder
                    }
                    UserDefaults.standard.lowMarkValueInUserChosenUnitRounded = input
                    operationCell.detailedText = UserDefaults.standard.lowMarkValueInUserChosenUnit.bgValuetoString(mgdl: isMg)
                    tableView.reloadRows(at: [indexPath], with: .none)
                }
                
                self.present(alert, animated: true, completion: nil)
             })
            .operationCell(title: R.string.settingsViews.settingsviews_urgentLowValue(),
                           detailedText: UserDefaults.standard.urgentLowMarkValueInUserChosenUnit.bgValuetoString(mgdl: isMg),
                           didClick: {
                [unowned self] operationCell, tableView, indexPath in
                
                let placeHolder = ConstantsBGGraphBuilder.defaultUrgentLowMarkInMgdl
                    .mgdlToMmolAndToString(mgdl: isMg)
                
                let alert = PopupDialog(
                    title: Texts_SettingsView.labelUrgentLowValue,
                    message: nil,
                    keyboardType: isMg ? .numberPad : .decimalPad,
                    text: UserDefaults.standard.urgentLowMarkValueInUserChosenUnitRounded,
                    placeHolder: placeHolder
                ) {
                    urgentLowMarkValue in
                    
                    var input = urgentLowMarkValue
                    if urgentLowMarkValue == "" {
                        input = placeHolder
                    }
                    UserDefaults.standard.urgentLowMarkValueInUserChosenUnitRounded = input
                    operationCell.detailedText = UserDefaults.standard.urgentLowMarkValueInUserChosenUnit.bgValuetoString(mgdl: isMg)
                    tableView.reloadRows(at: [indexPath], with: .none)
                }
                
                self.present(alert, animated: true, completion: nil)
             })
            .operationCell(title: R.string.settingsViews.settingsviews_chartHeight(),
                           detailedText: UserDefaults.standard.chartHeight.mgdlToMmolAndToString(mgdl: isMg),
                           didClick: {
                [unowned self] operationCell, tableView, indexPath in
                
                let heights: [Double] = [220, 300, 400]
                let shoAsMg = UserDefaults.standard.bloodGlucoseUnitIsMgDl
                var data = [String]()
                var selectedRow: Int?

                for (i, h) in heights.enumerated() {
                    data.append(h.mgdlToMmolAndToString(mgdl: shoAsMg))
                    if UserDefaults.standard.chartHeight == h {
                        selectedRow = i
                    }
                }
                
                let pickerViewData = PickerViewDataBuilder(
                    data: data,
                    actionHandler: {
                        index, _ in
                        if index != selectedRow {
                            UserDefaults.standard.chartHeight = heights[index]
                            operationCell.detailedText = heights[index].mgdlToMmolAndToString(mgdl: isMg)
                            tableView.reloadRows(at: [indexPath], with: .none)
                        }
                    }
                )
                    .title(R.string.settingsViews.settingsviews_chartHeight())
                    .selectedRow(selectedRow)
                    .build()
                
                BottomSheetPickerViewController.show(in: self, pickerViewData: pickerViewData)
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
