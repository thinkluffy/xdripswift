//
//  SettingsViewMoreSettingsViewModel.swift
//  xdrip
//
//  Created by Yuanbin Cai on 2021/11/4.
//  Copyright © 2021 Johan Degraeve. All rights reserved.
//

import UIKit
import MessageUI
import os

fileprivate enum Setting: Int, CaseIterable {

    case more = 0
    
}

class SettingsViewMoreSettingsViewModel: SettingsViewModelProtocol {
    
    func storeRowReloadClosure(rowReloadClosure: ((Int) -> Void)) {}
    
    func storeUIViewController(uIViewController: UIViewController) {}
    
    func storeMessageHandler(messageHandler: ((String, String) -> Void)) {
        // this ViewModel does need to send back messages to the viewcontroller asynchronously
    }
    
   func sectionTitle() -> String? {
       return R.string.settingsViews.sectionTitleMore()
    }
    
    func settingsRowText(index: Int) -> String {
        
        guard let setting = Setting(rawValue: index) else { fatalError("Unexpected Section") }
        
        switch setting {
            
        case .more:
            return R.string.settingsViews.moreSettings()
            
        }
        
    }
    
    func accessoryType(index: Int) -> UITableViewCell.AccessoryType {
        
        guard let setting = Setting(rawValue: index) else { fatalError("Unexpected Section") }
        
        switch setting {
            
        case .more:
            return .disclosureIndicator
            
        }
        
    }
    
    func detailedText(index: Int) -> String? {
        
        guard let setting = Setting(rawValue: index) else { fatalError("Unexpected Section") }
        
        switch setting {
            
        case .more:
            
            return nil
            
        }
    }
    
    func uiView(index: Int) -> UIView? {
        return nil
    }
    
    func numberOfRows() -> Int {
        return Setting.allCases.count
    }
    
    func onRowSelect(index: Int) -> SettingsSelectedRowAction {
        
        guard let setting = Setting(rawValue: index) else { fatalError("Unexpected Section") }
        
        switch setting {
            
        case .more:
            return .performSegue(withIdentifier: SettingsViewController.SegueIdentifiers.settingsToMore.rawValue, sender: nil)
        }
    }
    
    func isEnabled(index: Int) -> Bool {
        
        return true
        
    }
    
    func completeSettingsViewRefreshNeeded(index: Int) -> Bool {
        
        return false
        
    }
    

}
