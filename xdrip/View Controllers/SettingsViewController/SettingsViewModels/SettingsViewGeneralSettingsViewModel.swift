import UIKit

fileprivate enum Setting: Int, CaseIterable {
    
    /// blood glucose  unit
    case bloodGlucoseUnit = 0
    
    /// choose between master and follower
    case masterFollower = 1
         
    /// should reading be shown in notification
    case showReadingInNotification = 2
    
    /// - minimum time between two readings, for which notification should be created (in minutes)
    /// - except if there's been a disconnect, in that case this value is not taken into account
    case notificationInterval = 3
    
    /// show reading in app badge
    case showReadingInAppBadge = 4
    
}

/// conforms to SettingsViewModelProtocol for all general settings in the first sections screen
class SettingsViewGeneralSettingsViewModel: SettingsViewModelProtocol {
    
    func storeRowReloadClosure(rowReloadClosure: ((Int) -> Void)) {}
    
    func storeUIViewController(uIViewController: UIViewController) {}

    func storeMessageHandler(messageHandler: ((String, String) -> Void)) {
        // this ViewModel does need to send back messages to the viewcontroller asynchronously
    }
    
    func completeSettingsViewRefreshNeeded(index: Int) -> Bool {
        // changing follower to master or master to follower requires changing ui for nightscout settings and transmitter type settings
        // the same applies when changing bloodGlucoseUnit, because off the seperate section with bgObjectives
        if (index == Setting.masterFollower.rawValue || index == Setting.bloodGlucoseUnit.rawValue) {return true}
        
        return false
    }
    
    func isEnabled(index: Int) -> Bool {
        return true
    }
    
    func onRowSelect(index: Int) -> SettingsSelectedRowAction {
        guard let setting = Setting(rawValue: index) else { fatalError("Unexpected Section") }

        switch setting {
            
        case .bloodGlucoseUnit:
            return SettingsSelectedRowAction.callFunction(function: {
                
                UserDefaults.standard.bloodGlucoseUnitIsMgDl ? (UserDefaults.standard.bloodGlucoseUnitIsMgDl = false) : (UserDefaults.standard.bloodGlucoseUnitIsMgDl = true)
                
            })

        case .masterFollower:
            
            // switching from master to follower will set cgm transmitter to nil and stop the sensor. If there's a sensor active then it's better to ask for a confirmation, if not then do the change without asking confirmation
            if UserDefaults.standard.isMaster {
                if SensorsAccessor().fetchActiveSensor() != nil {
                    return .askConfirmation(title: Texts_Common.warning, message: Texts_SettingsView.warningChangeFromMasterToFollower, actionHandler: {
                        
                        UserDefaults.standard.isMaster = false
                        
                    }, cancelHandler: nil)

                } else {
                    // no sensor active
                    // set to follower
                    return SettingsSelectedRowAction.callFunction(function: {
                        UserDefaults.standard.isMaster = false
                    })
                }
                
            } else {
                // switching from follower to master
                return SettingsSelectedRowAction.callFunction(function: {
                    UserDefaults.standard.isMaster = true
                })
            }
            
        case .showReadingInNotification, .showReadingInAppBadge:
            return SettingsSelectedRowAction.nothing
            
        case .notificationInterval:
            return SettingsSelectedRowAction.askText(title: Texts_SettingsView.settingsviews_IntervalTitle, message: Texts_SettingsView.settingsviews_IntervalMessage, keyboardType: .numberPad, text: UserDefaults.standard.notificationInterval.description, placeHolder: "0", actionTitle: nil, cancelTitle: nil, actionHandler: {(interval:String) in if let interval = Int(interval) {UserDefaults.standard.notificationInterval = Int(interval)}}, cancelHandler: nil, inputValidator: nil)
            
        }
    }
    
    func sectionTitle() -> String? {
        return Texts_SettingsView.sectionTitleGeneral
    }

    func numberOfRows() -> Int {
        return Setting.allCases.count
    }

    func settingsRowText(index: Int) -> String {
        guard let setting = Setting(rawValue: index) else { fatalError("Unexpected Section") }

        switch setting {
            
        case .bloodGlucoseUnit:
            return Texts_SettingsView.labelSelectBgUnit
            
        case .masterFollower:
            return Texts_SettingsView.labelMasterOrFollower
            
        case .showReadingInNotification:
            return Texts_SettingsView.showReadingInNotification
            
        case .notificationInterval:
            return Texts_SettingsView.settingsviews_IntervalTitle
            
        case .showReadingInAppBadge:
            return Texts_SettingsView.labelShowReadingInAppBadge
            
        }
    }
    
    func accessoryType(index: Int) -> UITableViewCell.AccessoryType {
        guard let setting = Setting(rawValue: index) else { fatalError("Unexpected Section") }
        
        switch setting {
            
        case .bloodGlucoseUnit:
            return .none
    
        case .masterFollower:
            return .none
            
        case .showReadingInNotification, .showReadingInAppBadge:
            return .none
            
        case .notificationInterval:
            return .none
            
        }
    }
    
    func detailedText(index: Int) -> String? {
        guard let setting = Setting(rawValue: index) else { fatalError("Unexpected Section") }

        switch setting {
            
        case .bloodGlucoseUnit:
            return UserDefaults.standard.bloodGlucoseUnitIsMgDl ? Texts_Common.mgdl:Texts_Common.mmol
            
        case .masterFollower:
            return UserDefaults.standard.isMaster ? Texts_SettingsView.master:Texts_SettingsView.follower
            
        case .showReadingInNotification, .showReadingInAppBadge:
            return nil
            
        case .notificationInterval:
            return UserDefaults.standard.notificationInterval.description
        }
    }
    
    func uiView(index: Int) -> UIView? {
        guard let setting = Setting(rawValue: index) else { fatalError("Unexpected Section") }
        
        switch setting {
        case .showReadingInNotification:
            return UISwitch(isOn: UserDefaults.standard.showReadingInNotification) { isOn in
                UserDefaults.standard.showReadingInNotification = isOn
            }
            
        case .showReadingInAppBadge:
            return UISwitch(isOn: UserDefaults.standard.showReadingInAppBadge) { isOn in
                UserDefaults.standard.showReadingInAppBadge = isOn
            }

        case .bloodGlucoseUnit, .masterFollower:
            return nil
            
        case .notificationInterval:
            return nil
        }
    }
}
