//
//  DeveloperViewController.swift
//  xdrip
//
//  Created by Yuanbin Cai on 2021/12/24.
//  Copyright © 2021 Johan Degraeve. All rights reserved.
//

import UIKit

class DeveloperViewController: UIViewController {

    private lazy var tableView: UITableView = {
        UITableView(frame: .zero, style: .grouped)
    }()
    
    private var tableData: TableData!

    override func viewDidLoad() {
        super.viewDidLoad()
        tabBarController?.tabBar.isHidden = true

        title = "Developer"
        
        setupView()
        
        buildData()
    }
    
    private func setupView() {
        view.backgroundColor = ConstantsUI.mainBackgroundColor
        
        tableView.backgroundColor = ConstantsUI.mainBackgroundColor
        tableView.showsVerticalScrollIndicator = false
        
        view.addSubview(tableView)
        
        tableView.snp.makeConstraints { (make) in
            make.edges.equalTo(view.safeAreaLayoutGuide)
        }
    }
    
    private func buildData() {
        tableData = TableDataBuilder()
            .configure(
                titleTextColor: ConstantsUI.tableTitleColor,
                detailTextColor: ConstantsUI.tableDetailTextColor,
                sectionHeaderColor: ConstantsUI.tableViewHeaderTextColor
            )
        
            .section(headerTitle: "Infos")
            .operationCell(title: "Build Time", detailedText: getBuildTime())
            .operationCell(title: "First Open Time", detailedText: getInstallTime())
            .operationCell(title: "First Open Version", detailedText: String(UserDefaults.standard.firstOpenVersionCode))
            .operationCell(title: "Launch Count", detailedText: String(UserDefaults.standard.launchCount), didClick: {
                [unowned self] operationCell, tableView, indexPath in
               
                let alert = UIAlertController(title: "Reset Launch Count?", message: "Sure to reset?", preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "Reset", style: .default, handler: { action in
                    UserDefaults.standard.launchCount = 0
                    operationCell.detailedText = String(UserDefaults.standard.launchCount)
                    tableView.reloadRows(at: [indexPath], with: .none)
                }))
                alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
                self.present(alert, animated: true)
            })
        
            .section(headerTitle: "Common")
            .operationCell(title: "Remote Config Version", detailedText: String(RemoteConfigProxy.shared.versionId), didClick: { operationCell, tableView, indexPath in
                RemoteConfigProxy.shared.refresh() { refreshed in
                    self.view.makeToast("Refreshed!", duration: 2.0, position: .bottom)
                    operationCell.detailedText = String(RemoteConfigProxy.shared.versionId)
                    self.tableView.reloadRows(at: [indexPath], with: .none)
                }
            })
            .toggleCell(title: "Remote Config Test Mode", isOn: RemoteConfigHost.testMode, toggleDidChange: { from, to in
                RemoteConfigHost.testMode = !RemoteConfigHost.testMode

                self.navigationController?.view.makeToast("Restart app to apply", duration: 4.0, position: .bottom)
            })
            .operationCell(title: "Force a Crash", didClick: {
                [unowned self] operationCell, tableView, indexPath in
                
                let alert = UIAlertController(title: "Force a Crash", message: "Sure to crash?", preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "Crash", style: .destructive, handler: { action in
                    fatalError()
                }))
                alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
                self.present(alert, animated: true)
            })
            .operationCell(title: "Reset Agreement", didClick: {
                [unowned self] operationCell, tableView, indexPath in
                
                let alert = UIAlertController(title: "Reset Agreement", message: "Sure to reset?", preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "Reset", style: .destructive, handler: { action in
                    UserDefaults.standard.isAgreementAgreed = false
                    self.navigationController?.view.makeToast("Agreement has been reset", duration: 2.0, position: .bottom)
                }))
                alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
                self.present(alert, animated: true)
            })
            .build()
        
        tableView.delegate = tableData
        tableView.dataSource = tableData
    }
    
    private func getBuildTime() -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        return dateFormatter.string(from: iOS.appBuildDate)
    }
    
    private func getInstallTime() -> String {
        if let firstOpenTime =  UserDefaults.standard.firstOpenTime {
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
            return dateFormatter.string(from: firstOpenTime)
            
        } else {
            // should not be here
            return "Unkown"
        }
    }
}
