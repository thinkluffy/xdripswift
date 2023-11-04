import UIKit
import AVFoundation

fileprivate enum Setting: Int, CaseIterable {
    
    /// alert types
    case alertTypes = 0
    
    /// alerts
    case alerts = 1
    
    /// volume test for sound played by soundPlayer
    case volumeTestSoundPlayer = 2
    
}

/// conforms to SettingsViewModelProtocol for all alert settings in the first sections screen
struct SettingsViewAlertSettingsViewModel: SettingsViewModelProtocol {
    
    func storeUIViewController(uIViewController: UIViewController) {}

    func storeMessageHandler(messageHandler: ((String, String) -> Void)) {
        // this ViewModel does need to send back messages to the viewcontroller asynchronously
    }
    
    func completeSettingsViewRefreshNeeded(index: Int) -> Bool {
        return false
    }
        
    func isEnabled(index: Int) -> Bool {
        return true
    }
    
    func onRowSelect(index: Int) -> SettingsSelectedRowAction {
        guard let setting = Setting(rawValue: index) else { fatalError("Unexpected Setting in SettingsViewAlertSettingsViewModel onRowSelect") }

        switch setting {
        case .alertTypes:
            return .performSegue(withIdentifier: R.segue.totalAlertSettingsViewController.alertTypesSettings.identifier, sender: nil)
            
        case .alerts:
            return .performSegue(withIdentifier: R.segue.totalAlertSettingsViewController.alertsSettings.identifier, sender: nil)
            
        case .volumeTestSoundPlayer:
            
            // here the volume of the soundplayer will be tested.
            // soundplayer is used for alerts with override mute = on, except for missed reading alerts or any other delayed alert
            
            // start playing the xdripalert.wav
            SoundPlayer.shared.playSound(soundFileName: "xdripalert.wav")
            
            return .showInfoText(title: Texts_Common.warning, message: Texts_SettingsView.volumeTestSoundPlayerExplanation) {
                // user clicked ok, which will close the pop up and also player should stop playing
                SoundPlayer.shared.stopPlaying()
            }
        }
    }
    
    func storeRowReloadClosure(rowReloadClosure: ((Int) -> Void)) {}
    
    func sectionTitle() -> String? {
        return Texts_SettingsView.sectionTitleAlerting
    }
    
    func numberOfRows() -> Int {
        return Setting.allCases.count
    }
    
    func uiView(index: Int) -> UIView? {
        return nil
    }
    
    func settingsRowText(index: Int) -> String {
        guard let setting = Setting(rawValue: index) else {
            fatalError("Unexpected Setting in SettingsViewAlertSettingsViewModel onRowSelect")
        }
        
        switch setting {
        case .alertTypes:
            return Texts_SettingsView.labelAlertTypes
            
        case .alerts:
            return Texts_SettingsView.labelAlerts
            
        case .volumeTestSoundPlayer:
            return Texts_SettingsView.volumeTestSoundPlayer
        }
    }
    
    func accessoryType(index: Int) -> UITableViewCell.AccessoryType {
        guard let setting = Setting(rawValue: index) else { fatalError("Unexpected Section") }
        
        switch setting {
        case .alertTypes, .alerts:
            return .disclosureIndicator
            
        case .volumeTestSoundPlayer:
            return .none
        }
    }
    
    func detailedText(index: Int) -> String? {
        return nil
    }
}
