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
            .section(headerTitle: R.string.settingsViews.developerSettings())
            .toggleCell(title: R.string.settingsViews.nslog(), isOn: UserDefaults.standard.NSLogEnabled, toggleDidChange: { from, to in
                UserDefaults.standard.NSLogEnabled = to
            })
            .toggleCell(title: R.string.settingsViews.oslog(), isOn: UserDefaults.standard.OSLogEnabled, toggleDidChange: { from, to in
                UserDefaults.standard.OSLogEnabled = to
                if to {
                    Log.level = Log.Level.verbose
                    
                } else {
                    Log.level = Log.Level.warning
                }
            })
            .toggleCell(title: R.string.settingsViews.smoothLibreValues(), isOn: UserDefaults.standard.smoothLibreValues, icon: nil, toggleDidChange: { from, to in
                UserDefaults.standard.smoothLibreValues = to
            })

        tableData = tableDataBuilder.build()
        tableView.delegate = tableData
        tableView.dataSource = tableData
    }
}
