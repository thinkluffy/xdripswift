//
//  SettingsViewController.swift
//  xdrip
//
//  Created by Yuanbin Cai on 2021/12/12.
//  Copyright © 2021 Johan Degraeve. All rights reserved.
//

import UIKit

class SettingsViewController: UIViewController {

    @IBOutlet weak var tableView: UITableView!

    private var tableData: TableData!

    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = "zDrip"
        
        setupView()
        
        buildData()
    }

    private func setupView() {
        navigationController?.navigationBar.prefersLargeTitles = true
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
                           didClick: { [unowned self] operationCell, tableView, indexPath in
                let viewController = CommonSettingsViewController()
                self.navigationController?.pushViewController(viewController, animated: true)
            })
            .operationCell(title: "Legacy",
                           accessoryView: DTCustomColoredAccessory(color: ConstantsUI.disclosureIndicatorColor),
                           didClick: { [unowned self] operationCell, tableView, indexPath in
                let viewController = R.storyboard.main.legacySettingsViewController()!
                self.navigationController?.pushViewController(viewController, animated: true)
            })
            .build()
           
        tableView.delegate = tableData
        tableView.dataSource = tableData
    }
}
