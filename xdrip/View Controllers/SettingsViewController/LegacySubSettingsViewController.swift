//
//  LegacySubSettingsViewController.swift
//  xdrip
//
//  Created by Yuanbin Cai on 2021/12/15.
//  Copyright © 2021 Johan Degraeve. All rights reserved.
//

import UIKit
import PopupDialog

class LegacySettingSection {
    
    private let viewModelProtocol: SettingsViewModelProtocol
    
    init(viewModelProtocol: SettingsViewModelProtocol) {
        self.viewModelProtocol = viewModelProtocol
    }
    
    func viewModel() -> SettingsViewModelProtocol {
        return viewModelProtocol
    }
}

class LegacySubSettingsViewController: SubSettingsViewController {

    private lazy var tableView: UITableView = {
        let tableView = UITableView(frame: .zero, style: .insetGrouped)
        tableView.backgroundColor = ConstantsUI.mainBackgroundColor
        tableView.showsVerticalScrollIndicator = false
        return tableView
    }()
                
    /// will show pop up with title and message
    private var messageHandler: ((String, String) -> Void)?
    
    /// UIViewController used by messageHandler
    private var messageHandlerVC: UIViewController?
    
    /// array of viewmodels, one per section
    private var viewModels = [SettingsViewModelProtocol]()
        
    private var sections: [LegacySettingSection]?
    
    /// subclass should override this function
    func configureSections() -> [LegacySettingSection]? {
        return nil
    }
    
    private func configure() {
        sections = configureSections()
        guard let sections = sections else {
            return
        }
        
        // create messageHandler
        messageHandler = { (title, message) in
            
            // piece of code that we need two times
            let createAndPresentMessageHandlerVC = {
                self.messageHandlerVC = PopupDialog(
                    title: title,
                    message: message,
                    actionTitle: R.string.common.common_Ok(),
                    actionHandler: nil,
                    dismissHandler: {
                        self.messageHandlerVC = nil
                    }
                )
                
                if let messageHandlerVC = self.messageHandlerVC {
                    self.present(messageHandlerVC, animated: true)
                }
            }
            
            // first check if messageHandlerVC is not nil and is presenting. If it is, dismiss it and when completed call createAndPresentMessageHandlerVC
            if let messageHandlerVC = self.messageHandlerVC {
                messageHandlerVC.dismiss(animated: true, completion: createAndPresentMessageHandlerVC)
                return
            }

            // we're here which means there wasn't a messageHandlerUiAlertController being presented, so present it now
            createAndPresentMessageHandlerVC()
        }

        // initialize viewModels
        for (i, section) in sections.enumerated() {
            // get a viewModel for the section
            let viewModel = section.viewModel()
            
            // unwrap messageHandler and store in the viewModel
            if let messageHandler = messageHandler {
                viewModel.storeMessageHandler(messageHandler: messageHandler)
            }
            
            // store self as uiViewController in the viewModel
            viewModel.storeUIViewController(uIViewController: self)
            
            // store reload closure in the viewModel
            viewModel.storeRowReloadClosure() { row in
                self.tableView.reloadRows(at: [IndexPath(row: row, section: i)], with: .none)
            }

            // store the viewModel
            viewModels.append(viewModel)
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupView()
        
        configure()
    }
    
    private func setupView() {
        view.backgroundColor = ConstantsUI.mainBackgroundColor

        view.addSubview(tableView)
        
        tableView.snp.makeConstraints { make in
            make.edges.equalTo(view.safeAreaLayoutGuide)
        }
        
        tableView.dataSource = self
        tableView.delegate = self
    }
}

extension LegacySubSettingsViewController: UITableViewDataSource, UITableViewDelegate {
        
    func tableView(_ tableView: UITableView, willDisplayHeaderView view: UIView, forSection section: Int) {
        if let view = view as? UITableViewHeaderFooterView {
            view.textLabel?.textColor = ConstantsUI.tableViewHeaderTextColor
        }
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return viewModels[section].sectionTitle()
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return sections?.count ?? 0
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return viewModels[section].numberOfRows()
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        var cell = tableView.dequeueReusableCell(withIdentifier: "tableCell") ?? UITableViewCell(style: .value1, reuseIdentifier: "tableCell")
        
        // Configure Cell
        SettingsViewUtilities.configureSettingsCell(cell: &cell,
                                                    forRowWithIndex: indexPath.row,
                                                    forSectionWithIndex: indexPath.section,
                                                    withViewModel: viewModels[indexPath.section],
                                                    tableView: tableView)
        
        return cell
    }
        
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        let viewModel = viewModels[indexPath.section]
        
        if viewModel.isEnabled(index: indexPath.row) {
            let selectedRowAction = viewModel.onRowSelect(index: indexPath.row)
            
            SettingsViewUtilities.runSelectedRowAction(selectedRowAction: selectedRowAction,
                                                       forRowWithIndex: indexPath.row,
                                                       forSectionWithIndex: indexPath.section,
                                                       withSettingsViewModel: viewModel,
                                                       tableView: tableView,
                                                       forUIViewController: self)
        }
    }
    
    func tableView(_ tableView: UITableView, accessoryButtonTappedForRowWith indexPath: IndexPath) {
        // apple doc says : Use this method to respond to taps in the detail button accessory view of a row. The table view does not call this method for other types of accessory views.
        // when user clicks on of the detail buttons, then consider this as row selected, for now - as it's only license that is using this button for now
        self.tableView(tableView, didSelectRowAt: indexPath)
    }
}
