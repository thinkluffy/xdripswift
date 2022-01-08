import UIKit

fileprivate enum Setting: Int, CaseIterable {

    ///should readings be spoken or not
    case speakBgReadings = 0

    /// language to use
    case speakBgReadingLanguage = 1

    ///should trend be spoken or not
    case speakTrend = 2

    /// should delta be spoken or not
    case speakDelta = 3

    /// speak each reading, each 2 readings ...  integer value
    case speakInterval = 4

    /// speak reading only when not in range
    case speakOnlyWhenOutOfRange = 5

}

/// conforms to SettingsViewModelProtocol for all speak settings in the first sections screen
class SettingsViewSpeakSettingsViewModel: SettingsViewModelProtocol {

    func storeRowReloadClosure(rowReloadClosure: (Int) -> Void) {
    }

    func storeUIViewController(uIViewController: UIViewController) {
    }

    func storeMessageHandler(messageHandler: (String, String) -> Void) {
        // this ViewModel does need to send back messages to the viewcontroller asynchronously
    }

    func completeSettingsViewRefreshNeeded(index: Int) -> Bool {
        false
    }

    func isEnabled(index: Int) -> Bool {
        true
    }

    func onRowSelect(index: Int) -> SettingsSelectedRowAction {
        guard let setting = Setting(rawValue: index) else {
            fatalError("Unexpected Section")
        }

        switch setting {
        case .speakBgReadings:
            return .nothing

        case .speakTrend:
            return .nothing

        case .speakDelta:
            return .nothing

        case .speakInterval:
            var data = [String]()
            for i in 1...30 {
                data.append(R.string.common.howManyMinutes(i))
            }
            let selectedRow = UserDefaults.standard.speakInterval - 1

            return .selectFromList(
                    title: R.string.settingsViews.settingsviews_IntervalTitle(),
                    message: R.string.settingsViews.settingsviews_IntervalMessage(),
                    data: data,
                    selectedRow: selectedRow,
                    actionTitle: R.string.common.common_Ok(),
                    actionHandler: { index in
                        if selectedRow != index {
                            UserDefaults.standard.speakInterval = index + 1
                        }
                    },
                    cancelHandler: nil,
                    didSelectRowHandler: nil
            )

        case .speakBgReadingLanguage:

            //find index for languageCode type currently stored in userDefaults
            var selectedRow: Int?
            if let languageCode = UserDefaults.standard.speakReadingLanguageCode {
                selectedRow = ConstantsSpeakReadingLanguages.allLanguageNamesAndCodes.codes.firstIndex(of: languageCode)

            } else {
                selectedRow = ConstantsSpeakReadingLanguages.allLanguageNamesAndCodes.codes.firstIndex(of: Texts_SpeakReading.defaultLanguageCode)
            }

            return .selectFromList(
                    title: Texts_SettingsView.speakReadingLanguageSelection,
                    message: nil,
                    data: ConstantsSpeakReadingLanguages.allLanguageNamesAndCodes.names,
                    selectedRow: selectedRow,
                    actionTitle: nil,
                    actionHandler: {
                        (index: Int) in

                        if index != selectedRow {
                            UserDefaults.standard.speakReadingLanguageCode = ConstantsSpeakReadingLanguages.allLanguageNamesAndCodes.codes[index]
                        }
                    },
                    cancelHandler: nil,
                    didSelectRowHandler: nil)

        case .speakOnlyWhenOutOfRange:
            return .nothing
        }
    }

    func sectionTitle() -> String? {
        Texts_SettingsView.sectionTitleSpeak
    }

    func numberOfRows() -> Int {
        if !UserDefaults.standard.speakReadings {
            return 1

        } else {
            return Setting.allCases.count
        }
    }

    func settingsRowText(index: Int) -> String {
        guard let setting = Setting(rawValue: index) else {
            fatalError("Unexpected Section")
        }

        switch setting {
        case .speakBgReadings:
            return Texts_SettingsView.labelSpeakBgReadings
        case .speakBgReadingLanguage:
            return Texts_SettingsView.labelSpeakLanguage
        case .speakTrend:
            return Texts_SettingsView.labelSpeakTrend
        case .speakDelta:
            return Texts_SettingsView.labelSpeakDelta
        case .speakInterval:
            return Texts_SettingsView.settingsviews_IntervalTitle
        case .speakOnlyWhenOutOfRange:
            return R.string.settingsViews.settingsviews_speakWhenOutOfRange()
        }
    }

    func accessoryType(index: Int) -> UITableViewCell.AccessoryType {
        .none
    }

    func detailedText(index: Int) -> String? {
        guard let setting = Setting(rawValue: index) else {
            fatalError("Unexpected Section")
        }

        switch setting {
        case .speakBgReadings:
            return nil
        case .speakTrend:
            return nil
        case .speakDelta:
            return nil
        case .speakInterval:
            return R.string.common.howManyMinutes(UserDefaults.standard.speakInterval)
        case .speakBgReadingLanguage:
            return Texts_SpeakReading.languageName
        case .speakOnlyWhenOutOfRange:
            return nil
        }
    }

    func uiView(index: Int) -> UIView? {
        guard let setting = Setting(rawValue: index) else {
            fatalError("Unexpected Section")
        }

        switch setting {

        case .speakBgReadings:
            return UISwitch(isOn: UserDefaults.standard.speakReadings) {
                (isOn: Bool) in
                UserDefaults.standard.speakReadings = isOn
            }

        case .speakTrend:
            return UISwitch(isOn: UserDefaults.standard.speakTrend) {
                (isOn: Bool) in
                UserDefaults.standard.speakTrend = isOn
            }

        case .speakDelta:
            return UISwitch(isOn: UserDefaults.standard.speakDelta) {
                (isOn: Bool) in
                UserDefaults.standard.speakDelta = isOn
            }

        case .speakInterval:
            return nil

        case .speakBgReadingLanguage:
            return nil

        case .speakOnlyWhenOutOfRange:
            return UISwitch(isOn: UserDefaults.standard.speakOnlyWhenOutOfRange) {
                (isOn: Bool) in
                UserDefaults.standard.speakOnlyWhenOutOfRange = isOn
            }
        }
    }
}
