//
//  MoreSettingsViewController.swift
//  xdrip
//
//  Created by Yuanbin Cai on 2021/11/4.
//  Copyright © 2021 Johan Degraeve. All rights reserved.
//

import UIKit
import MessageUI

class MoreSettingsViewController: UIViewController {
    
    @IBOutlet weak var tableView: UITableView!

    private var tableData: TableData!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        title = R.string.settingsViews.moreSettings()

        setupView()
        
        buildData()
    }

    private func setupView() {
        
    }
    
    private func buildData() {
//        var sectionVerticalMargin: CGFloat? = nil
//        if #available(iOS 13, *) {
//            sectionVerticalMargin = 10
//        }
        
        let tableDataBuilder = TableDataBuilder()
            .configure(cellBackgroundColor: UIColor.rgba(46, 46, 46),
                       titleTextColor: .white,
                       toggleButtonThumbColorOn: nil,
                       toggleButtonBgColorOn: nil,
                       sectionVerticalMargin: nil)
            
            // issue reporting
            .section(headerTitle: R.string.settingsViews.sectionTitleTrace(), footerTitle: nil)
            .operationCell(id: 1, title: R.string.settingsViews.sendTraceFile(), detailedText: nil, icon: nil, accessoryView: nil, didClick: { [unowned self] operationCell, idnexPath in
                
                // check if iOS device can send email, this depends of an email account is configured
                if MFMailComposeViewController.canSendMail() {
                    
                    let alert = UIAlertController(title: R.string.homeView.info(), message: R.string.settingsViews.describeProblem("abc"), actionHandler: {
                        
                        let mail = MFMailComposeViewController()
                        mail.mailComposeDelegate = self
                        mail.setToRecipients([ConstantsTrace.traceFileDestinationAddress])
                        mail.setMessageBody(Texts_SettingsView.emailbodyText, isHTML: true)
                        
                        // add all trace files as attachment
                        let traceFilesInData = Trace.getTraceFilesInData()
                        for (index, traceFileInData) in traceFilesInData.0.enumerated() {
                            mail.addAttachmentData(traceFileInData as Data, mimeType: "text/txt", fileName: traceFilesInData.1[index])
                        }
                        
                        if let appInfoAsData = Trace.getAppInfoFileAsData().0 {
                            mail.addAttachmentData(appInfoAsData as Data, mimeType: "text/txt", fileName: Trace.getAppInfoFileAsData().1)
                        }
                        
                        self.present(mail, animated: true)
                    
                    }, cancelHandler: nil)
                    
                    self.present(alert, animated: true, completion: nil)
                    
                } else {
                    let alert = UIAlertController(title: R.string.common.warning(), message: R.string.settingsViews.emailNotConfigured(), actionHandler: nil)
                    
                    self.present(alert, animated: true, completion: nil)
                }
            })
            .toggleCell(title: R.string.settingsViews.debugLevel(), isOn: UserDefaults.standard.addDebugLevelLogsInTraceFileAndNSLog, icon: nil, toggleDidChange: { from, to in
                UserDefaults.standard.addDebugLevelLogsInTraceFileAndNSLog = to
            })
            
            // about
            .section(headerTitle: R.string.settingsViews.settingsviews_sectiontitleAbout(iOS.appDisplayName), footerTitle: nil)
            .operationCell(id: 21, title: R.string.settingsViews.settingsviews_Version(), detailedText: iOS.appVersionName, icon: nil, accessoryView: nil, didClick: nil)
            .operationCell(id: 22, title: R.string.settingsViews.settingsviews_build(), detailedText: "\(iOS.appVersionCode)", icon: nil, accessoryView: nil, didClick: nil)
            .operationCell(id: 23, title: R.string.settingsViews.settingsviews_license(), detailedText: nil, icon: nil, accessoryView: nil, didClick: {
                [unowned self] operationCell, idnexPath in
                let alert = UIAlertController(title: iOS.appDisplayName, message: R.string.homeView.licenseinfo(), actionHandler: nil)
                self.present(alert, animated: true, completion: nil)
            })
            .operationCell(id: 24, title: "Icons by icons8.com", detailedText: nil, icon: nil, accessoryView: nil, didClick: {
                operationCell, idnexPath in
                guard let url = URL(string: "https://icons8.com") else { return }
                UIApplication.shared.open(url)
            })
        
            // developer
            .section(headerTitle: R.string.settingsViews.developerSettings(), footerTitle: nil)
            .toggleCell(title: R.string.settingsViews.nslog(), isOn: UserDefaults.standard.NSLogEnabled, icon: nil, toggleDidChange: { from, to in
                UserDefaults.standard.NSLogEnabled = to
            })
            .toggleCell(title: R.string.settingsViews.oslog(), isOn: UserDefaults.standard.OSLogEnabled, icon: nil, toggleDidChange: { from, to in
                UserDefaults.standard.OSLogEnabled = to
            })
            .toggleCell(title: R.string.settingsViews.smoothLibreValues(), isOn: UserDefaults.standard.smoothLibreValues, icon: nil, toggleDidChange: { from, to in
                UserDefaults.standard.smoothLibreValues = to
            })
//            .toggleCell(title: R.string.app.text_vibrate_when_painting(), isOn: ConfigHost.isVibrationEnabled, icon: R.image.icon.ic_vibrate(), toggleDidChange: { from, to in
//                ConfigHost.isVibrationEnabled = to
//                EasyTracker.logEvent(to ? Events.TurnOnVibration : Events.TurnOffVibration)
//            })
//            .toggleCell(title: R.string.common.sound(), isOn: ConfigHost.isSoundEnabled, icon: R.image.icon.ic_sound(), toggleDidChange: { from, to in
//                ConfigHost.isSoundEnabled = to
//                EasyTracker.logEvent(to ? Events.TurnOnSound : Events.TurnOffSound)
//            })
//            .toggleCell(title: R.string.common.music(), isOn: ConfigHost.isMusicEnabled, icon: R.image.icon.ic_music(), toggleDidChange: { from, to in
//                ConfigHost.isMusicEnabled = to
//                EasyTracker.logEvent(to ? Events.TurnOnMusic : Events.TurnOffMusic)
//            })
//            .operationCell(id: TABLE_CELL_ID_HINT_COLOR, title: R.string.app.title_hint_color(), icon: R.image.icon.ic_hint_color(),
//                           accessoryView: UIImageView(image: ConfigHost.hintColor.accessoryImage),
//                           didClick: { [unowned self] operationCell, indexPath in
//                let vc = HintColorViewController()
//                self.navigationController?.pushViewController(vc, animated: true)
//            })
//
//            .section()
//            .operationCell(title: R.string.common.upgrade_to_pro(), icon: R.image.icon.ic_setting_pro(), didClick: { [unowned self] operationCell, indexPath in
//                PTUtils.showLicenseUpgradeView(from: self)
//            })
//            .operationCell(title: R.string.app.text_rate_stars(), icon: R.image.icon.ic_star(), didClick: { operationCell, indexPath in
//                RatingDialogViewController().show(in: self) { (dialog, stars) in
//                    SettingsViewController.log.i("Rating stars, \(stars)")
//                    dialog.dismiss()
//
//                    EasyTracker.logEvent(Events.RatingInSetting, parameters: EasyTracker.value(stars))
//                    //SKStoreReviewController.requestReview()
//                    Utils.openAppReview(appId: Constants.APP_ID)
//                }
//            })
//            .operationCell(title: R.string.common.contact_us(), icon: R.image.icon.ic_contact(), didClick: { operationCell, indexPath in
//                // TODO: put this in Utils, as a common function
//                let version = iOS.appVersionName
//
//                let dateFormat = DateFormatter()
//                dateFormat.formatterBehavior = .behavior10_4 // 10.4+ style
//                dateFormat.dateFormat = "yyyy/MM/dd-HH:mm:ss"
//
//                let timeStamp = dateFormat.string(from: Date())
//                if (MFMailComposeViewController.canSendMail()) {
//                    let controller = MFMailComposeViewController()
//                    controller.mailComposeDelegate = self
//                    controller.setToRecipients([Constants.SUPPORT_MAIL])
//                    controller.setSubject("[\(Constants.INTERNAL_APP_NAME)][\(version)][\(timeStamp)]")
//
//                    let body = "\n\n\n\n\n\n\n\n\n\n\n-----------------------------------------------\n[\(iOS.platform)][\(iOS.systemVersion)]"
//
//                    controller.setMessageBody(body, isHTML: false)
//                    self.present(controller, animated: true, completion: nil)
//
//                } else {
//                    let url = "mailto:\(Constants.SUPPORT_MAIL)?subject=[\(Constants.INTERNAL_APP_NAME)][\(version)][\(timeStamp)]"
//
//                    let encodeUrlSet = NSCharacterSet.urlQueryAllowed
//
//                    guard let encodeUrl = url.addingPercentEncoding(withAllowedCharacters: encodeUrlSet),
//                        let urlToOpen = URL(string: encodeUrl) else {
//                            return
//                    }
//
//                    UIApplication.shared.open(urlToOpen, options: [:])
//                }
//            })
//            .operationCell(title: R.string.localizable.about(), icon: R.image.ic_about(), didClick: { [weak self] operationCell, indexPath in
//
//            })
        

        tableData = tableDataBuilder.build()
        tableView.delegate = tableData
        tableView.dataSource = tableData
    }

}

extension MoreSettingsViewController: MFMailComposeViewControllerDelegate {
    
    func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?) {
        
        controller.dismiss(animated: true, completion: nil)
        
        switch result {
            
        case .cancelled:
            break
            
        case .sent, .saved:
            break
            
        case .failed:
           break
            
        @unknown default:
            break
            
        }
        
    }
    
}
