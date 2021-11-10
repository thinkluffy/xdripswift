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
        tableView.backgroundColor = ConstantsUI.mainBackgroundColor
    }
    
    private func buildData() {
        let tableDataBuilder = TableDataBuilder()
            .configure(cellBackgroundColor: nil,
                       titleTextColor: ConstantsUI.tableTitleColor,
                       detailTextColor: ConstantsUI.tableDetailTextColor,
                       toggleButtonThumbColorOn: nil,
                       toggleButtonBgColorOn: nil,
                       sectionVerticalMargin: nil,
                       sectionHeaderColor: ConstantsUI.tableViewHeaderTextColor)
            
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
