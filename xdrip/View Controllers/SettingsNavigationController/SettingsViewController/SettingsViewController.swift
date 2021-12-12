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
