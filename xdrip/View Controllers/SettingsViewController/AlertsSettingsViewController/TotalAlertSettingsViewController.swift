//
//  TotalAlertSettingsViewController.swift
//  xdrip
//
//  Created by Yuanbin Cai on 2021/12/15.
//  Copyright © 2021 Johan Degraeve. All rights reserved.
//

import UIKit

class TotalAlertSettingsViewController: LegacySubSettingsViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        title = R.string.settingsViews.settingsviews_row_alerts()
    }
    
    override func configureSections() -> [LegacySettingSection]? {
        return [
            LegacySettingSection(viewModelProtocol: SettingsViewAlertSettingsViewModel())
        ]
    }
}