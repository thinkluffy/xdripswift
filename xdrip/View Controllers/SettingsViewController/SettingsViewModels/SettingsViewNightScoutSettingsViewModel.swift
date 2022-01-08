import UIKit
import os
import Foundation

fileprivate enum Setting: Int, CaseIterable {

    /// should readings be uploaded or not
    case nightScoutEnabled = 0

    /// nightScout url
    case nightScoutUrl = 1

    /// nightScout api key
    case nightScoutAPIKey = 2

    /// nightScout api key
    case token = 3

    /// port
    case port = 4

    /// to allow testing explicitly
    case testUrlAndAPIKey = 5

    /// should sensor start time be uploaded to NS yes or no
    case uploadSensorStartTime = 6
}

class SettingsViewNightScoutSettingsViewModel {

    // MARK: - properties

    /// in case info message or errors occur like credential check error, then this closure will be called with title and message
    /// - parameters:
    ///     - first parameter is title
    ///     - second parameter is the message
    ///
    /// the viewController sets it by calling storeMessageHandler
    private var messageHandler: ((String, String) -> Void)?

    private static let log = Log(type: SettingsViewNightScoutSettingsViewModel.self)

    private func testNightScoutCredentials() {
        let resultCallback = { (success: Bool, error: Error?) in
            if success {
                self.callMessageHandlerInMainThread(title: Texts_NightScoutTestResult.verificationSuccessfulAlertTitle,
                        message: Texts_NightScoutTestResult.verificationSuccessfulAlertBody)

            } else {
                let errorCode = (error as NSError?)?.code ?? 0
                self.callMessageHandlerInMainThread(
                        title: R.string.nightScoutTestResult.dialog_title_nightScoutResult_verification_failed(),
                        message: R.string.nightScoutTestResult.dialog_msg_nightScoutResult_verification_failed(errorCode)
                )
            }
        }

        if UserDefaults.standard.isMaster {
            NightScoutUploadManager.testNightScoutCredentials(resultCallback)

        } else {
            NightScoutFollowManager.testNightScoutCredentials(resultCallback)
        }
    }

    private func callMessageHandlerInMainThread(title: String, message: String) {
        // unwrap messageHandler
        guard let messageHandler = messageHandler else {
            return
        }

        DispatchQueue.main.async {
            messageHandler(title, message)
        }
    }
}

/// conforms to SettingsViewModelProtocol for all nightscout settings in the first sections screen
extension SettingsViewNightScoutSettingsViewModel: SettingsViewModelProtocol {

    func storeRowReloadClosure(rowReloadClosure: (Int) -> Void) {
    }

    func storeUIViewController(uIViewController: UIViewController) {
    }

    func storeMessageHandler(messageHandler: @escaping (String, String) -> Void) {
        self.messageHandler = messageHandler
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

        case .nightScoutEnabled:
            return .nothing

        case .nightScoutUrl:
            return .askText(
                    title: Texts_SettingsView.labelNightScoutUrl,
                    message: Texts_SettingsView.giveNightScoutUrl,
                    keyboardType: .URL,
                    text: UserDefaults.standard.nightScoutUrl,
                    placeHolder: nil,
                    actionTitle: nil,
                    cancelTitle: nil,
                    actionHandler: {
                        (nightScoutUrl: String) in

                        // assuming that the enteredURL isn't nil, isn't the default value and hasn't been entered without a valid scheme
                        if let enteredURL = nightScoutUrl.toNilIfLength0() {

                            var urlString = enteredURL

                            // if self doesn't start with http or https, then add https. This might not make sense, but it will guard against throwing fatal errors when trying to get the scheme of the Endpoint
                            if !urlString.startsWith("http://") && !urlString.startsWith("https://") {
                                urlString = "https://" + urlString
                            }

                            // if url ends with /, remove it
                            if urlString.last == "/" {
                                urlString.removeLast()
                            }

                            // remove the api path if it exists - useful for people pasting in xDrip+ Base URLs
                            urlString = urlString.replacingOccurrences(of: "/api/v1", with: "")

                            // if we've got a valid URL, then let's break it down
                            if let enteredURLComponents = URLComponents(string: urlString) {

                                // pull the port info if it exists and set the port
                                if let port = enteredURLComponents.port {
                                    UserDefaults.standard.nightScoutPort = port
                                }

                                // pull the "user" info if it exists and use it to set the API_SECRET
                                if let user = enteredURLComponents.user {
                                    UserDefaults.standard.nightScoutAPIKey = user.toNilIfLength0()
                                }

                                // if the user has pasted in a URL with a token, then let's parse it out and use it
                                if let token = enteredURLComponents.queryItems?.first(where: { $0.name == "token" })?.value {
                                    UserDefaults.standard.nightScoutToken = token.toNilIfLength0()
                                }

                                // finally, let's make a clean URL with just the scheme and host. We don't need to add anything else as this is basically the only thing we were asking for in the first place.
                                var nighScoutURLComponents = URLComponents()
                                nighScoutURLComponents.scheme = enteredURLComponents.scheme
                                nighScoutURLComponents.host = enteredURLComponents.host?.lowercased()

                                UserDefaults.standard.nightScoutUrl = nighScoutURLComponents.string!
                            }

                        } else {
                            // there must be something wrong with the URL the user is trying to add, so let's just ignore it
                            UserDefaults.standard.nightScoutUrl = nil
                        }
                    },
                    cancelHandler: nil,
                    inputValidator: nil
            )

        case .nightScoutAPIKey:
            return .askText(
                    title: Texts_SettingsView.labelNightScoutAPIKey,
                    message: Texts_SettingsView.giveNightScoutAPIKey,
                    keyboardType: .default,
                    text: UserDefaults.standard.nightScoutAPIKey,
                    placeHolder: nil,
                    actionTitle: nil,
                    cancelTitle: nil,
                    actionHandler: {
                        (apiKey: String) in

                        UserDefaults.standard.nightScoutAPIKey = apiKey.toNilIfLength0()
                    },
                    cancelHandler: nil,
                    inputValidator: nil
            )

        case .port:
            return .askText(
                    title: Texts_SettingsView.nightScoutPort,
                    message: nil,
                    keyboardType: .numberPad,
                    text: UserDefaults.standard.nightScoutPort != 0 ? UserDefaults.standard.nightScoutPort.description : nil,
                    placeHolder: nil,
                    actionTitle: nil,
                    cancelTitle: nil,
                    actionHandler: {
                        (port: String) in

                        if let port = port.toNilIfLength0() {
                            UserDefaults.standard.nightScoutPort = Int(port) ?? 0

                        } else {
                            UserDefaults.standard.nightScoutPort = 0
                        }
                    },
                    cancelHandler: nil,
                    inputValidator: nil
            )

        case .token:
            return .askText(
                    title: R.string.settingsViews.nightScoutToken(),
                    message: nil,
                    keyboardType: .default,
                    text: UserDefaults.standard.nightScoutToken,
                    placeHolder: nil,
                    actionTitle: nil,
                    cancelTitle: nil,
                    actionHandler: {
                        (token: String) in

                        UserDefaults.standard.nightScoutToken = token.toNilIfLength0()
                    },
                    cancelHandler: nil,
                    inputValidator: nil
            )

        case .testUrlAndAPIKey:
            guard UserDefaults.standard.nightScoutUrl != nil else {
                if let messageHandler = messageHandler {
                    messageHandler(R.string.common.warning(), R.string.settingsViews.dialog_ns_input_url_before_test())
                }
                return .nothing
            }

            // show info that test is started, through the messageHandler
            if let messageHandler = messageHandler {
                messageHandler(Texts_NightScoutTestResult.nightScoutAPIKeyAndURLStartedTitle, Texts_NightScoutTestResult.nightScoutAPIKeyAndURLStartedBody)
            }

            testNightScoutCredentials()

            return .nothing

        case .uploadSensorStartTime:
            return .nothing
        }
    }

    func sectionTitle() -> String? {
        Texts_SettingsView.sectionTitleNightScout
    }

    func numberOfRows() -> Int {
        // if nightScout upload not enabled then only first row is shown
        if UserDefaults.standard.nightScoutEnabled {
            // in follower mode, only 6 first rows to be shown : nightScout enabled button, url, port number, token, api key, option to test
            if !UserDefaults.standard.isMaster {
                return 6
            }
            return Setting.allCases.count

        } else {
            return 1
        }
    }

    func settingsRowText(index: Int) -> String {
        guard let setting = Setting(rawValue: index) else {
            fatalError("Unexpected Section")
        }

        switch setting {

        case .nightScoutEnabled:
            return Texts_SettingsView.labelNightScoutEnabled
        case .nightScoutUrl:
            return Texts_SettingsView.labelNightScoutUrl
        case .nightScoutAPIKey:
            return Texts_SettingsView.labelNightScoutAPIKey
        case .port:
            return Texts_SettingsView.nightScoutPort
        case .token:
            return R.string.settingsViews.nightScoutToken()
        case .uploadSensorStartTime:
            return Texts_SettingsView.uploadSensorStartTime
        case .testUrlAndAPIKey:
            return UserDefaults.standard.isMaster ? R.string.settingsViews.testUrlAndAPIKeyInMasterMode() : R.string.settingsViews.testUrlAndAPIKeyInFollowerMode()
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
        case .nightScoutEnabled:
            return nil
        case .nightScoutUrl:
            return UserDefaults.standard.nightScoutUrl
        case .nightScoutAPIKey:
            return UserDefaults.standard.nightScoutAPIKey != nil ? obscureString(stringToObscure: UserDefaults.standard.nightScoutAPIKey) : nil
        case .port:
            return UserDefaults.standard.nightScoutPort != 0 ? UserDefaults.standard.nightScoutPort.description : nil
        case .token:
            return UserDefaults.standard.nightScoutToken != nil ? obscureString(stringToObscure: UserDefaults.standard.nightScoutToken) : nil
        case .uploadSensorStartTime:
            return nil
        case .testUrlAndAPIKey:
            return nil
        }
    }

    func uiView(index: Int) -> UIView? {
        guard let setting = Setting(rawValue: index) else {
            fatalError("Unexpected Section")
        }

        switch setting {

        case .nightScoutEnabled:
            return UISwitch(isOn: UserDefaults.standard.nightScoutEnabled) { isOn in
                UserDefaults.standard.nightScoutEnabled = isOn
            }

        case .nightScoutUrl:
            return nil

        case .nightScoutAPIKey:
            return nil

        case .port:
            return nil

        case .token:
            return nil

        case .uploadSensorStartTime:
            return UISwitch(isOn: UserDefaults.standard.uploadSensorStartTimeToNS) { isOn in
                UserDefaults.standard.uploadSensorStartTimeToNS = isOn
            }

        case .testUrlAndAPIKey:
            return nil
        }
    }

    /// use this to partially obscure the API-SECRET and Token values. We want the user to see that "something" is there that makes sense to them, but it won't reveal any private information if they screenshot it
    func obscureString(stringToObscure: String?) -> String {

        // make sure that something useful has been passed to the function
        guard var obscuredString = stringToObscure else {
            return ""
        }

        let stringLength: Int = obscuredString.count

        // in order to avoid strange layouts if somebody uses a really long API_SECRET, then let's limit the displayed string size to something more manageable
        let maxStringSizeToShow: Int = 12

        // the characters we will use to obscure the sensitive data
        let maskingCharacter: String = "*"

        // based upon the length of the string, we will show more, or less, of the original characters at the beginning. This gives more context whilst maintaining privacy
        var startCharsNotToObscure: Int = 0

        switch stringLength {
        case 0...3:
            startCharsNotToObscure = 0
        case 4...5:
            startCharsNotToObscure = 1
        case 6...7:
            startCharsNotToObscure = 2
        case 8...10:
            startCharsNotToObscure = 3
        case 11...50:
            startCharsNotToObscure = 4
        default:
            startCharsNotToObscure = 0
        }

        // remove the characters that we want to obscure
        obscuredString.removeLast(stringLength - startCharsNotToObscure)

        // now "fill up" the string with the masking character up to the original string size. If it is longer than the maxStingSizeToShow then trim it down to make everything fit in a clean way
        obscuredString += String(repeating: maskingCharacter, count: stringLength > maxStringSizeToShow ? maxStringSizeToShow - obscuredString.count : stringLength - obscuredString.count)

        return obscuredString

    }
}

