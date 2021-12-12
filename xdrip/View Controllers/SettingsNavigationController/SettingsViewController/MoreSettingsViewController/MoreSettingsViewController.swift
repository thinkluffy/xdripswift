//
//  MoreSettingsViewController.swift
//  xdrip
//
//  Created by Yuanbin Cai on 2021/11/4.
//  Copyright © 2021 Johan Degraeve. All rights reserved.
//

import UIKit
import MessageUI

class MoreSettingsViewController: SubSettingsViewController {
    
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
            .configure(titleTextColor: ConstantsUI.tableTitleColor,
                       detailTextColor: ConstantsUI.tableDetailTextColor,
                       sectionHeaderColor: ConstantsUI.tableViewHeaderTextColor)
            
            // issue reporting
            .section(headerTitle: R.string.settingsViews.sectionTitleTrace())
            .operationCell(title: R.string.settingsViews.sendTraceFile(),
                           didClick: {
                [unowned self] operationCell, tableView, indexPath in
                
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
                    })
                    
                    self.present(alert, animated: true, completion: nil)
                    
                } else {
                    let alert = UIAlertController(title: R.string.common.warning(), message: R.string.settingsViews.emailNotConfigured(), actionHandler: nil)
                    
                    self.present(alert, animated: true, completion: nil)
                }
            })
            .toggleCell(title: R.string.settingsViews.debugLevel(), isOn: UserDefaults.standard.addDebugLevelLogsInTraceFileAndNSLog, toggleDidChange: { from, to in
                UserDefaults.standard.addDebugLevelLogsInTraceFileAndNSLog = to
            })
            
            // about
            .section(headerTitle: R.string.settingsViews.settingsviews_sectiontitleAbout(iOS.appDisplayName))
            .operationCell(title: R.string.settingsViews.settingsviews_Version(), detailedText: iOS.appVersionName)
            .operationCell(title: R.string.settingsViews.settingsviews_build(), detailedText: "\(iOS.appVersionCode)")
        
            // developer
            .section(headerTitle: R.string.settingsViews.developerSettings())
            .toggleCell(title: R.string.settingsViews.nslog(), isOn: UserDefaults.standard.NSLogEnabled, toggleDidChange: { from, to in
                UserDefaults.standard.NSLogEnabled = to
            })
            .toggleCell(title: R.string.settingsViews.oslog(), isOn: UserDefaults.standard.OSLogEnabled, toggleDidChange: { from, to in
                UserDefaults.standard.OSLogEnabled = to
                if to {
                    Log.level = Log.Level.verbose
                    
                } else {
                    Log.level = Log.Level.warning
                }
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
