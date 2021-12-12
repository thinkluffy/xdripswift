//
//  CommonSettingsViewController.swift
//  xdrip
//
//  Created by Yuanbin Cai on 2021/12/12.
//  Copyright © 2021 Johan Degraeve. All rights reserved.
//

import UIKit

class CommonSettingsViewController: SubSettingsViewController {

    private let tableView: UITableView = {
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
        view.addSubview(tableView)
        
        tableView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }
    
    private func buildData() {
        tableData = TableDataBuilder()
            .configure(titleTextColor: ConstantsUI.tableTitleColor,
                       detailTextColor: ConstantsUI.tableDetailTextColor,
                       sectionHeaderColor: ConstantsUI.tableViewHeaderTextColor)
            
            // common
            .section(headerTitle: R.string.settingsViews.settingsviews_sectiontitlegeneral())
            .operationCell(title: R.string.settingsViews.settingsviews_selectbgunit(),
                           detailedText: UserDefaults.standard.bloodGlucoseUnitIsMgDl ? R.string.common.common_mgdl() : R.string.common.common_mmol(),
                           didClick: { operationCell, tableView, indexPath in
                let isMgDlNow = !UserDefaults.standard.bloodGlucoseUnitIsMgDl
                UserDefaults.standard.bloodGlucoseUnitIsMgDl = isMgDlNow
                operationCell.detailedText = isMgDlNow ? R.string.common.common_mgdl() : R.string.common.common_mmol()
                tableView.reloadSections(IndexSet(integer: indexPath.section), with: .none)
            })
            .operationCell(title: R.string.settingsViews.settingsviews_masterorfollower(),
                           detailedText: UserDefaults.standard.isMaster ? R.string.settingsViews.settingsviews_master() : R.string.settingsViews.settingsviews_follower(),
                           didClick: { [unowned self] operationCell, tableView, indexPath in
                
            })
            .toggleCell(title: R.string.settingsViews.settingsviews_showReadingInNotification(),
                        isOn: UserDefaults.standard.showReadingInNotification, toggleDidChange: { from, to in
                UserDefaults.standard.showReadingInNotification = to
            })
            .operationCell(title: R.string.settingsViews.settingsviews_IntervalTitle(),
                           detailedText: R.string.common.howManyMinutes(UserDefaults.standard.notificationInterval),
                           didClick: { [unowned self] operationCell, tableView, indexPath in
                
            })
            .toggleCell(title: R.string.settingsViews.settingsviews_labelShowReadingInAppBadge(),
                        isOn: UserDefaults.standard.showReadingInAppBadge, toggleDidChange: { from, to in
                UserDefaults.standard.showReadingInAppBadge = to
            })
            .build()
           
        tableView.delegate = tableData
        tableView.dataSource = tableData
    }
}
