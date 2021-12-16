//
//  NotesViewController.swift
//  xdrip
//
//  Created by Yuanbin Cai on 2021/12/16.
//  Copyright © 2021 Johan Degraeve. All rights reserved.
//

import UIKit

class NotesViewController: UIViewController {

    private static let log = Log(type: NotesViewController.self)
    
    private lazy var calendarTitle: CalendarTitle = {
        let calendarTitle = CalendarTitle()
        return calendarTitle
    }()
    
    private lazy var tableView: UITableView = {
        let tableView = UITableView(frame: .zero, style: .plain)
        tableView.backgroundColor = ConstantsUI.contentBackgroundColor
        return tableView
    }()
    
    // set the status bar content colour to light to match new darker theme
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = "Notes"
        
        setupView()
        
        calendarTitle.dateTime = Date()
    }
    
    private func setupView() {
        view.backgroundColor = ConstantsUI.mainBackgroundColor
        
        let titleBar = UIView()
        
        view.addSubview(titleBar)
        titleBar.addSubview(calendarTitle)
        view.addSubview(tableView)
        
        titleBar.snp.makeConstraints { make in
            make.leading.top.trailing.equalTo(view.safeAreaLayoutGuide)
            make.height.equalTo(50)
        }
        
        calendarTitle.snp.makeConstraints { make in
            make.center.equalToSuperview()
        }
        
        tableView.snp.makeConstraints { make in
            make.leading.bottom.trailing.equalToSuperview()
            make.top.equalTo(titleBar.snp.bottom)
        }
    }
}
