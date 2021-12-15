//
//  ServiceIntegrationSettingsViewController.swift
//  xdrip
//
//  Created by Yuanbin Cai on 2021/12/15.
//  Copyright © 2021 Johan Degraeve. All rights reserved.
//

import UIKit

class ServiceIntegrationSettingsViewController: LegacySubSettingsViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = R.string.settingsViews.serviceIntegration()
    }
    
    override func configureSections() -> [LegacySettingSection]? {
        var sections = [LegacySettingSection]()
        
        sections.append(LegacySettingSection(viewModelProtocol: SettingsViewNightScoutSettingsViewModel()))
        sections.append(LegacySettingSection(viewModelProtocol: SettingsViewDexcomSettingsViewModel()))
        sections.append(LegacySettingSection(viewModelProtocol: SettingsViewHealthKitSettingsViewModel()))
        sections.append(LegacySettingSection(viewModelProtocol: SettingsViewAppleWatchSettingsViewModel()))
                    
        return sections
    }
}
