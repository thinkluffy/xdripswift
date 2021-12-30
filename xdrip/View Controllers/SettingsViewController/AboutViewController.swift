//
//  AboutViewController.swift
//  xdrip
//
//  Created by Yuanbin Cai on 2021/12/16.
//  Copyright © 2021 Johan Degraeve. All rights reserved.
//

import UIKit
import PopupDialog

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
        
        let longPressGesture = UILongPressGestureRecognizer(target: self, action: #selector(copyrightDidLongPress(_:)))
        copyRightLabel.addGestureRecognizer(longPressGesture)
        copyRightLabel.isUserInteractionEnabled = true
    }
    
    private func buildData() {
        tableData = TableDataBuilder()
            .configure(titleTextColor: ConstantsUI.tableTitleColor,
                       detailTextColor: ConstantsUI.tableDetailTextColor,
                       sectionHeaderColor: ConstantsUI.tableViewHeaderTextColor)
        
#if DEBUG
            .operationCell(title: R.string.settingsViews.settingsviews_Version(), detailedText: "v\(iOS.appVersionName)-DEBUG")
#else
            .operationCell(title: R.string.settingsViews.settingsviews_Version(), detailedText: "v\(iOS.appVersionName)")
#endif
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
            .operationCell(title: R.string.settingsViews.check_app_version(), detailedText: nil, didClick: { [unowned self] operationCell, tableView, indexPath in
                
                let json = RemoteConfigHost.latestVersion
                if let versionCode = json["version_code"].int,
                   let versionName = json["version_name"].string,
                   versionCode > iOS.appVersionCode {
                    self.view.makeToast(R.string.settingsViews.toast_newer_app_version(versionName), duration: 4, position: .bottom)
                    
                } else {
                    self.view.makeToast(R.string.settingsViews.toast_no_newer_app_version(), duration: 2, position: .bottom)
                }
            })
            .operationCell(title: R.string.common.privacyPolicy(),
                           accessoryView: DTCustomColoredAccessory(color: ConstantsUI.disclosureIndicatorColor),
                           didClick: {
                [unowned self] operationCell, tableView, indexPath in
                
                if let url = URL(string: Constants.privacyPolicyUrl) {
                    let viewController = WebViewViewController(url: url, title: R.string.common.privacyPolicy())
                    navigationController?.pushViewController(viewController, animated: true)
                }
            })

            .build()
        
        tableView.delegate = tableData
        tableView.dataSource = tableData
    }
    
    @objc private func copyrightDidLongPress(_ gesture: UILongPressGestureRecognizer) {
        guard gesture.state == .began else {
            return
        }
        
        if UserDefaults.standard.isDeveloperConsoleOpened {
            let vc = DeveloperViewController()
            navigationController?.pushViewController(vc, animated: true)
            return
        }
        
        let dialog = PopupDialog(title: "Should I open the door", message: nil, keyboardType: .default, text: nil, placeHolder: nil) {
            _, text in
            let sanded = text + "zd" + text.reversed()
            // goodluck#1
            if "7545387dc50ba53e7c3e37f04b5def118e82544bbbe47ac4eb10837a8a3b05a3" == sanded.sha256 {
                UserDefaults.standard.isDeveloperConsoleOpened = true

                let vc = DeveloperViewController()
                self.navigationController?.pushViewController(vc, animated: true)
            }
        }
        
        present(dialog, animated: true)
    }
}
