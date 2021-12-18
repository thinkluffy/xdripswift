//
//  NotesViewController.swift
//  xdrip
//
//  Created by Yuanbin Cai on 2021/12/16.
//  Copyright © 2021 Johan Degraeve. All rights reserved.
//

import UIKit
import FSCalendar

class NotesViewController: UIViewController {

    private static let log = Log(type: NotesViewController.self)
    
    private var presenter: NotesP!

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
        
        instancePresenter()

        title = "Notes"
        
        setupView()
        
        calendarTitle.dateTime = Date()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        presenter.onViewDidAppear()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        presenter.onViewWillDisappear()
        super.viewWillDisappear(animated)
    }
    
    private func instancePresenter() {
        presenter = NotesPresenter(view: self)
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
        
        calendarTitle.delegate = self
    }
}

extension NotesViewController: NotesV {
    
}

extension NotesViewController: CalendarTitleDelegate {
    
    func calendarLeftButtonDidClick(_ calendarTitle: CalendarTitle, currentTime: Date) {
        if let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: currentTime) {
            presenter.loadData(date: yesterday)
        }
    }
    
    func calendarRightButtonDidClick(_ calendarTitle: CalendarTitle, currentTime: Date) {
        if let nextDay = Calendar.current.date(byAdding: .day, value: 1, to: currentTime) {
            presenter.loadData(date: nextDay)
        }
    }
    
    func calendarTitleDidClick(_ calendarTitle: CalendarTitle) {
        guard let selectedDate = calendarTitle.dateTime else {
            return
        }
        
        let content = DatePickerSheetContent(selectedDate: selectedDate, slideInFrom: .top)
        content.delegate = self
        let sheet = SlideInSheet(sheetContent: content)
        sheet.show(in: view, dimColor: .black.withAlphaComponent(0.5), slideInFrom: .top)
    }
}

extension NotesViewController: DatePickerSheetContentDelegate {
    
    func datePickerSheetContent(_ sheetContent: DatePickerSheetContent, didSelect date: Date) {
        // double check to avoid selecting a date in future
        guard date < Date() else {
            return
        }
        
        sheetContent.sheet?.dismissView()
        presenter.loadData(date: date)
    }
}

