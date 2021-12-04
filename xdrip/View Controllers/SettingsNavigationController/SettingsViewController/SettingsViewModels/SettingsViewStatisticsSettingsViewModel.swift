//
//  SettingsViewStatisticsSettingsViewModel.swift
//  xdrip
//
//  Created by Paul Plant on 25/04/21.
//  Copyright © 2021 Johan Degraeve. All rights reserved.
//

import Foundation

import UIKit

fileprivate enum Setting: Int, CaseIterable {
    
    //should we use the user values for High + Low, or use the standard range?
    case useStandardStatisticsRange = 0
    
    //urgent low value
    case useIFCCA1C = 1
    
}

/// conforms to SettingsViewModelProtocol for all general settings in the first sections screen
struct SettingsViewStatisticsSettingsViewModel:SettingsViewModelProtocol {
    
    func uiView(index: Int) -> UIView? {
        guard let setting = Setting(rawValue: index) else { fatalError("Unexpected Section") }
        
        switch setting {

        case .useStandardStatisticsRange :
            return UISwitch(isOn: UserDefaults.standard.useStandardStatisticsRange) { isOn in UserDefaults.standard.useStandardStatisticsRange = isOn
            }
            
        case .useIFCCA1C :
            return UISwitch(isOn: UserDefaults.standard.useIFCCA1C) { isOn in
                UserDefaults.standard.useIFCCA1C = isOn
            }
        }
    }
    
    func completeSettingsViewRefreshNeeded(index: Int) -> Bool {
        return false
    }
    
    func storeRowReloadClosure(rowReloadClosure: ((Int) -> Void)) {}
    
    func storeUIViewController(uIViewController: UIViewController) {}

    func storeMessageHandler(messageHandler: ((String, String) -> Void)) {
        // this ViewModel does need to send back messages to the viewcontroller asynchronously
    }
    
    func isEnabled(index: Int) -> Bool {
        return true
    }
    
    func onRowSelect(index: Int) -> SettingsSelectedRowAction {
        guard let setting = Setting(rawValue: index) else { fatalError("Unexpected Section") }
        
        switch setting {
        case .useStandardStatisticsRange:
            return SettingsSelectedRowAction.callFunction(function: {
                if UserDefaults.standard.useStandardStatisticsRange {
                    UserDefaults.standard.useStandardStatisticsRange = false
                } else {
                    UserDefaults.standard.useStandardStatisticsRange = true
                }
            })
            
        case .useIFCCA1C:
            return SettingsSelectedRowAction.callFunction(function: {
                if UserDefaults.standard.useIFCCA1C {
                    UserDefaults.standard.useIFCCA1C = false
                } else {
                    UserDefaults.standard.useIFCCA1C = true
                }
            })
        }
    }
    
    func sectionTitle() -> String? {
        return Texts_SettingsView.sectionTitleStatistics
    }
    
    func numberOfRows() -> Int {
        return Setting.allCases.count
    }
    
    func settingsRowText(index: Int) -> String {
        guard let setting = Setting(rawValue: index) else { fatalError("Unexpected Section") }
        
        switch setting {
            case .useStandardStatisticsRange:
                return Texts_SettingsView.labelUseStandardStatisticsRange
                    
            case .useIFCCA1C:
                return Texts_SettingsView.labelUseIFFCA1C
        }
    }
    
    func accessoryType(index: Int) -> UITableViewCell.AccessoryType {
        guard let setting = Setting(rawValue: index) else { fatalError("Unexpected Section") }
        
        switch setting {
        case .useStandardStatisticsRange, .useIFCCA1C:
            return .none
        }
    }
    
    func detailedText(index: Int) -> String? {
        guard let setting = Setting(rawValue: index) else { fatalError("Unexpected Section") }
        
        switch setting {
        case .useStandardStatisticsRange, .useIFCCA1C:
            return nil
        }
    }
    
}
