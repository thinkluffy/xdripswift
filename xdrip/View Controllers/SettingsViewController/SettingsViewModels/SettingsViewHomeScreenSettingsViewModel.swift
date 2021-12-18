//
//  SettingsViewHomeScreenSettingsViewModel.swift
//  xdrip
//
//  Created by Paul Plant on 09/06/2020.
//  Copyright © 2020 Johan Degraeve. All rights reserved.
//

import UIKit

fileprivate enum Setting: Int, CaseIterable {
    
    //urgent high value
    case urgentHighMarkValue = 0
    
    //high value
    case highMarkValue = 1
    
    //low value
    case lowMarkValue = 2
    
    //urgent low value
    case urgentLowMarkValue = 3
    
    //height of the chart, 12.2, 16.6 or 22
    case chartHeight = 4
    
    //chart dots 5 minuts apart?
    case chartDots5MinsApart = 5
        
}

/// conforms to SettingsViewModelProtocol for all general settings in the first sections screen
struct SettingsViewHomeScreenSettingsViewModel: SettingsViewModelProtocol {
    
    func uiView(index: Int) -> UIView? {
        
        guard let setting = Setting(rawValue: index) else { fatalError("Unexpected Section") }
        
        switch setting {

        case .chartDots5MinsApart :
            return UISwitch(isOn: UserDefaults.standard.chartDots5MinsApart) {
                isOn in
                UserDefaults.standard.chartDots5MinsApart = isOn
            }
        
        case .urgentHighMarkValue, .highMarkValue, .lowMarkValue, .urgentLowMarkValue, .chartHeight:
            return nil
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
                
        case .urgentHighMarkValue:
            return SettingsSelectedRowAction.askText(
                title: Texts_SettingsView.labelUrgentHighValue,
                message: nil,
                keyboardType: UserDefaults.standard.bloodGlucoseUnitIsMgDl ? .numberPad:.decimalPad,
                text: UserDefaults.standard.urgentHighMarkValueInUserChosenUnitRounded,
                placeHolder: ConstantsBGGraphBuilder.defaultUrgentHighMarkInMgdl.description,
                actionTitle: nil,
                cancelTitle: nil,
                actionHandler: { urgentHighMarkValue in
                    UserDefaults.standard.urgentHighMarkValueInUserChosenUnitRounded = urgentHighMarkValue
                },
                cancelHandler: nil,
                inputValidator: nil)

        case .highMarkValue:
            return SettingsSelectedRowAction.askText(title: Texts_SettingsView.labelHighValue, message: nil, keyboardType: UserDefaults.standard.bloodGlucoseUnitIsMgDl ? .numberPad:.decimalPad, text: UserDefaults.standard.highMarkValueInUserChosenUnitRounded, placeHolder: ConstantsBGGraphBuilder.defaultHighMarkInMgdl.description, actionTitle: nil, cancelTitle: nil, actionHandler: {(highMarkValue:String) in UserDefaults.standard.highMarkValueInUserChosenUnitRounded = highMarkValue}, cancelHandler: nil, inputValidator: nil)
        
        case .lowMarkValue:
            return SettingsSelectedRowAction.askText(title: Texts_SettingsView.labelLowValue, message: nil, keyboardType: UserDefaults.standard.bloodGlucoseUnitIsMgDl ? .numberPad:.decimalPad, text: UserDefaults.standard.lowMarkValueInUserChosenUnitRounded, placeHolder: ConstantsBGGraphBuilder.defaultLowMarkInMgdl.description, actionTitle: nil, cancelTitle: nil, actionHandler: {(lowMarkValue:String) in UserDefaults.standard.lowMarkValueInUserChosenUnitRounded = lowMarkValue}, cancelHandler: nil, inputValidator: nil)

        case .urgentLowMarkValue:
            return SettingsSelectedRowAction.askText(title: Texts_SettingsView.labelUrgentLowValue, message: nil, keyboardType: UserDefaults.standard.bloodGlucoseUnitIsMgDl ? .numberPad:.decimalPad, text: UserDefaults.standard.urgentLowMarkValueInUserChosenUnitRounded, placeHolder: ConstantsBGGraphBuilder.defaultUrgentLowMarkInMgdl.description, actionTitle: nil, cancelTitle: nil, actionHandler: {(urgentLowMarkValue:String) in UserDefaults.standard.urgentLowMarkValueInUserChosenUnitRounded = urgentLowMarkValue}, cancelHandler: nil, inputValidator: nil)
            
        case .chartHeight:
            let heights: [Double] = [220, 300, 400]
            let shoAsMg = UserDefaults.standard.bloodGlucoseUnitIsMgDl
            var data = [String]()
            var selectedRow: Int?

            for (i, h) in heights.enumerated() {
                data.append(h.mgdlToMmolAndToString(mgdl: shoAsMg))
                if UserDefaults.standard.chartHeight == h {
                    selectedRow = i
                }
            }
            
            return .selectFromList(
                title: R.string.settingsViews.settingsviews_chartHeight(),
                message: nil,
                data: data,
                selectedRow: selectedRow,
                actionTitle: nil,
                actionHandler: {
                    (index: Int) in
                    if index != selectedRow {
                        UserDefaults.standard.chartHeight = heights[index]
                    }
                },
                cancelHandler: nil,
                didSelectRowHandler: nil)
            
        case .chartDots5MinsApart:
            return SettingsSelectedRowAction.callFunction(function: {
                if UserDefaults.standard.chartDots5MinsApart {
                    UserDefaults.standard.chartDots5MinsApart = false
                    
                } else {
                    UserDefaults.standard.chartDots5MinsApart = true
                }
            })
        }
    }
    
    func sectionTitle() -> String? {
        return Texts_SettingsView.sectionTitleHomeScreen
    }
    
    func numberOfRows() -> Int {
        return Setting.allCases.count
    }
    
    func settingsRowText(index: Int) -> String {
        guard let setting = Setting(rawValue: index) else { fatalError("Unexpected Section") }

        switch setting {
                
        case .urgentHighMarkValue:
            return Texts_SettingsView.labelUrgentHighValue

        case .highMarkValue:
            return Texts_SettingsView.labelHighValue
            
        case .lowMarkValue:
            return Texts_SettingsView.labelLowValue
            
        case .urgentLowMarkValue:
            return Texts_SettingsView.labelUrgentLowValue
            
        case .chartHeight:
            return R.string.settingsViews.settingsviews_chartHeight()
            
        case .chartDots5MinsApart:
            return R.string.settingsViews.settingsviews_chartDots5MinsApart()
        }
    }
    
    func accessoryType(index: Int) -> UITableViewCell.AccessoryType {
        guard let setting = Setting(rawValue: index) else { fatalError("Unexpected Section") }
        
        switch setting {
            
        case .urgentHighMarkValue, .highMarkValue, .lowMarkValue, .urgentLowMarkValue, .chartDots5MinsApart:
            return .none

        case .chartHeight:
            return .none
        }
    }
    
    func detailedText(index: Int) -> String? {
        guard let setting = Setting(rawValue: index) else { fatalError("Unexpected Section") }

        switch setting {
        case .urgentHighMarkValue:
            return UserDefaults.standard.urgentHighMarkValueInUserChosenUnit.bgValuetoString(mgdl: UserDefaults.standard.bloodGlucoseUnitIsMgDl)
                
        case .highMarkValue:
            return UserDefaults.standard.highMarkValueInUserChosenUnit.bgValuetoString(mgdl: UserDefaults.standard.bloodGlucoseUnitIsMgDl)

        case .lowMarkValue:
            return UserDefaults.standard.lowMarkValueInUserChosenUnit.bgValuetoString(mgdl: UserDefaults.standard.bloodGlucoseUnitIsMgDl)

        case .urgentLowMarkValue:
            return UserDefaults.standard.urgentLowMarkValueInUserChosenUnit.bgValuetoString(mgdl: UserDefaults.standard.bloodGlucoseUnitIsMgDl)
            
        case .chartHeight:
            return UserDefaults.standard.chartHeight.mgdlToMmolAndToString(mgdl: UserDefaults.standard.bloodGlucoseUnitIsMgDl)
            
        case .chartDots5MinsApart:
            return nil
        }
    }
}
