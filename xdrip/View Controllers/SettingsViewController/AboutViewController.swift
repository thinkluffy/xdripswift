//
//  AboutViewController.swift
//  xdrip
//
//  Created by Yuanbin Cai on 2021/12/16.
//  Copyright © 2021 Johan Degraeve. All rights reserved.
//

import UIKit

class AboutViewController: LegacySubSettingsViewController {

    private static let log = Log(type: AboutViewController.self)
    
    private lazy var logoImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.image = R.image.logoLaunchScreen()
        imageView.backgroundColor = ConstantsUI.contentBackgroundColor
        imageView.layer.cornerRadius = 10
        return imageView
    }()
    
    private lazy var tableView: UITableView = {
        let tableView = UITableView(frame: .zero, style: .insetGrouped)
        tableView.backgroundColor = ConstantsUI.mainBackgroundColor
        tableView.alwaysBounceVertical = false
        return tableView
    }()
    
    private lazy var copyRightLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 14)
        label.textColor = .white.withAlphaComponent(0.6)
        label.text = "© \(iOS.appDisplayName)"
        return label
    }()
    
    private var tableData: TableData!

    private var buildClickCount = 0
    private var buildClickTimestamp: Date?

    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = R.string.common.about()
        
        setupView()
        
        buildData()
    }

    private func setupView() {
        view.backgroundColor = ConstantsUI.mainBackgroundColor
        
        view.addSubview(logoImageView)
        view.addSubview(tableView)
        view.addSubview(copyRightLabel)
        
        logoImageView.snp.makeConstraints { make in
            make.size.equalTo(100)
            make.centerX.equalToSuperview()
            make.top.equalToSuperview().offset(150)
        }
        
        copyRightLabel.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.bottom.equalTo(view.layoutMarginsGuide).offset(-20)
        }
        
        tableView.snp.makeConstraints { make in
            make.top.equalTo(logoImageView.snp.bottom).offset(50)
            make.leading.trailing.equalToSuperview()
            make.bottom.equalTo(copyRightLabel.snp.top).offset(-10)
        }
    }
    
    private func buildData() {
        tableData = TableDataBuilder()
            .configure(titleTextColor: ConstantsUI.tableTitleColor,
                       detailTextColor: ConstantsUI.tableDetailTextColor,
                       sectionHeaderColor: ConstantsUI.tableViewHeaderTextColor)
            
            .operationCell(title: R.string.settingsViews.settingsviews_Version(), detailedText: iOS.appVersionName)
            .operationCell(title: R.string.settingsViews.settingsviews_build(), detailedText: "\(iOS.appVersionCode)", didClick: { [unowned self] operationCell, tableView, indexPath in
                
                guard !UserDefaults.standard.isFullFeatureMode else {
                    return
                }
                
                let date = Date()
                
                guard let buildClickTimestamp = buildClickTimestamp else {
                    self.buildClickTimestamp = date
                    return
                }
                
                if date.timeIntervalSince(buildClickTimestamp) < 2 {
                    self.buildClickCount += 1
                    
                } else {
                    self.buildClickTimestamp = nil
                    self.buildClickCount = 0
                    return
                }
                    
                if self.buildClickCount > 10 {
                    AboutViewController.log.w("Full feature mode enabled!")
                    
                    UserDefaults.standard.isFullFeatureMode = true
                    
                    self.buildClickTimestamp = nil
                    self.buildClickCount = 0
                    self.view.makeToast(R.string.common.developerModeEnabled(), duration: 2, position: .bottom)
                }
            })
            .build()
        
        tableView.delegate = tableData
        tableView.dataSource = tableData
    }
}
