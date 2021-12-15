//
//  SettingsViewController.swift
//  xdrip
//
//  Created by Yuanbin Cai on 2021/12/12.
//  Copyright © 2021 Johan Degraeve. All rights reserved.
//

import UIKit

class SettingsViewController: UIViewController {

    private lazy var sloganLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 18)
        label.textColor = .white.withAlphaComponent(0.6)
        return label
    }()
    
    private lazy var tableView: UITableView = {
        let tableView = UITableView(frame: .zero, style: .insetGrouped)
        tableView.backgroundColor = ConstantsUI.mainBackgroundColor
        return tableView
    }()
    
    private var tableData: TableData!

    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = iOS.appDisplayName
        
        setupView()
        
        buildData()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        if let firstOpenTime = UserDefaults.standard.firstOpenTime {
            let interval = Date().timeIntervalSince(firstOpenTime)
            let days = Int((interval / Date.dayInSeconds).rounded(.up))
            sloganLabel.text = R.string.common.slogan(days)
        }
    }
    
    private func setupView() {
        navigationController?.navigationBar.prefersLargeTitles = true
        
        view.backgroundColor = ConstantsUI.mainBackgroundColor
        
        view.addSubview(sloganLabel)
        view.addSubview(tableView)
        
        sloganLabel.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide)
            make.leading.equalToSuperview().offset(18)
        }
        
        tableView.snp.makeConstraints { make in
            make.top.equalTo(sloganLabel.snp.bottom).offset(10)
            make.leading.bottom.trailing.equalTo(view.safeAreaLayoutGuide)
        }
    }
    
    private func buildData() {
        tableData = TableDataBuilder()
            .configure(titleTextColor: ConstantsUI.tableTitleColor,
                       detailTextColor: ConstantsUI.tableDetailTextColor,
                       sectionHeaderColor: ConstantsUI.tableViewHeaderTextColor)
           
            .operationCell(title: R.string.settingsViews.settingsviews_masterorfollower(),
                           detailedText: UserDefaults.standard.isMaster ? R.string.settingsViews.settingsviews_master() : R.string.settingsViews.settingsviews_follower(),
                           didClick: {
                [unowned self] operationCell, tableView, indexPath in
                
                // switching from master to follower will set cgm transmitter to nil and stop the sensor. If there's a sensor active then it's better to ask for a confirmation, if not then do the change without asking confirmation
                if UserDefaults.standard.isMaster {
                    if SensorsAccessor().fetchActiveSensor() != nil {
                        let alert = UIAlertController(title: R.string.common.warning(),
                                                      message: R.string.settingsViews.warningChangeFromMasterToFollower(),
                                                      preferredStyle: .alert)
                        
                        alert.addAction(UIAlertAction(title: R.string.common.common_Ok(), style: .default, handler: { _ in
                            UserDefaults.standard.isMaster = false
                            operationCell.detailedText = R.string.settingsViews.settingsviews_follower()
                            tableView.reloadRows(at: [indexPath], with: .none)
                        }))
                        
                        alert.addAction(UIAlertAction(title: R.string.common.common_cancel(), style: .cancel))

                        self.present(alert, animated: true)
                        
                    } else {
                        // no sensor active
                        // set to follower
                        UserDefaults.standard.isMaster = false
                        operationCell.detailedText = R.string.settingsViews.settingsviews_follower()
                        tableView.reloadRows(at: [indexPath], with: .none)
                    }
                    
                } else {
                    UserDefaults.standard.isMaster = true
                    operationCell.detailedText = R.string.settingsViews.settingsviews_master()
                    tableView.reloadRows(at: [indexPath], with: .none)
                }
            })
            .operationCell(title: R.string.settingsViews.settingsviews_selectbgunit(),
                           detailedText: UserDefaults.standard.bloodGlucoseUnitIsMgDl ? R.string.common.common_mgdl() : R.string.common.common_mmol(),
                           didClick: {
                operationCell, tableView, indexPath in
                
                let isMgDlNow = !UserDefaults.standard.bloodGlucoseUnitIsMgDl
                UserDefaults.standard.bloodGlucoseUnitIsMgDl = isMgDlNow
                operationCell.detailedText = isMgDlNow ? R.string.common.common_mgdl() : R.string.common.common_mmol()
                tableView.reloadRows(at: [indexPath], with: .none)
            })
        
            .operationCell(title: R.string.settingsViews.commonSettings(),
                           accessoryView: DTCustomColoredAccessory(color: ConstantsUI.disclosureIndicatorColor),
                           didClick: {
                [unowned self] operationCell, tableView, indexPath in
                
                let viewController = CommonSettingsViewController()
                self.navigationController?.pushViewController(viewController, animated: true)
            })
            .operationCell(title: R.string.settingsViews.settingsviews_row_alerts(),
                           accessoryView: DTCustomColoredAccessory(color: ConstantsUI.disclosureIndicatorColor),
                           didClick: {
                [unowned self] operationCell, tableView, indexPath in
                
                let viewController = R.storyboard.main.totalAlertSettingsViewController()!
                self.navigationController?.pushViewController(viewController, animated: true)
            })
            .operationCell(title: R.string.settingsViews.serviceIntegration(),
                           accessoryView: DTCustomColoredAccessory(color: ConstantsUI.disclosureIndicatorColor),
                           didClick: {
                [unowned self] operationCell, tableView, indexPath in
                
                let viewController = ServiceIntegrationSettingsViewController()
                self.navigationController?.pushViewController(viewController, animated: true)
            })
            .operationCell(title: R.string.settingsViews.settingsviews_speakBgReadings(),
                           accessoryView: DTCustomColoredAccessory(color: ConstantsUI.disclosureIndicatorColor),
                           didClick: {
                [unowned self] operationCell, tableView, indexPath in
                
                let viewController = SpeakReadingSettingsViewController()
                self.navigationController?.pushViewController(viewController, animated: true)
            })
            .build()
           
        tableView.delegate = tableData
        tableView.dataSource = tableData
    }
}
