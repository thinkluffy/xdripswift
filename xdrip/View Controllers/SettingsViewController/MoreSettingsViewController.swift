//
//  MoreSettingsViewController.swift
//  xdrip
//
//  Created by Yuanbin Cai on 2021/11/4.
//  Copyright © 2021 Johan Degraeve. All rights reserved.
//

import UIKit
import MessageUI

class MoreSettingsViewController: SubSettingsViewController {
    
    private lazy var tableView: UITableView = {
        let tableView = UITableView(frame: .zero, style: .insetGrouped)
        tableView.backgroundColor = ConstantsUI.mainBackgroundColor
        return tableView
    }()
    
    private var tableData: TableData!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = R.string.settingsViews.moreSettings()

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
        let tableDataBuilder = TableDataBuilder()
            .configure(titleTextColor: ConstantsUI.tableTitleColor,
                       detailTextColor: ConstantsUI.tableDetailTextColor,
                       sectionHeaderColor: ConstantsUI.tableViewHeaderTextColor)
            
            // developer
            .toggleCell(title: "Log", isOn: UserDefaults.standard.LogEnabled, toggleDidChange: { from, to in
                UserDefaults.standard.LogEnabled = to
                if to {
                    Log.level = Log.Level.verbose
                    
                } else {
                    Log.level = Log.Level.warning
                }
            })
            .toggleCell(title: R.string.settingsViews.smoothBgValues(), isOn: UserDefaults.standard.smoothBgReadings, icon: nil, toggleDidChange: { from, to in
                UserDefaults.standard.smoothBgReadings = to
            })

        tableData = tableDataBuilder.build()
        tableView.delegate = tableData
        tableView.dataSource = tableData
    }
}