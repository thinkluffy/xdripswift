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

    private lazy var calendarTitle: CalendarTitle = {
        let calendarTitle = CalendarTitle()
        return calendarTitle
    }()
    
    private lazy var tableView: UITableView = {
        let tableView = UITableView(frame: .zero, style: .plain)
        tableView.backgroundColor = ConstantsUI.contentBackgroundColor
        tableView.separatorColor = .white.withAlphaComponent(0.1)
        tableView.indicatorStyle = .white
        return tableView
    }()
    
    private lazy var emptyViewLabel: UILabel = {
        let label = UILabel()
        label.text = R.string.notes.emptyview_no_notes()
        label.textColor = .lightText
        label.font = .systemFont(ofSize: 25)
        label.isHidden = true
        return label
    }()
    
    private var presenter: NotesP!

    private let cellReuseIdentifier = "NoteTableViewCell"

    private var showingDate: Date?
    private var notes: [Note]?
    
    // set the status bar content colour to light to match new darker theme
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        instancePresenter()

        title = "Notes"
        
        setupView()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        presenter.onViewDidAppear()
        
        presenter.loadData(date: showingDate ?? Date())
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
        view.addSubview(emptyViewLabel)
        
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
        
        emptyViewLabel.snp.makeConstraints { make in
            make.center.equalToSuperview()
        }
        
        calendarTitle.delegate = self
        
        tableView.register(NoteTableViewCell.self, forCellReuseIdentifier: cellReuseIdentifier)

        tableView.delegate = self
        tableView.dataSource = self
    }
}

extension NotesViewController: NotesV {
    
    func show(notes: [Note]?, from fromDate: Date, to toDate: Date) {
        // setup calendar title
        calendarTitle.dateTime = fromDate
        let isToday = Calendar.current.isDateInToday(fromDate)
        calendarTitle.showRightArrow = !isToday
        
        self.notes = notes
        
//        if let notes = notes {
//            notes.forEach { note in
//                print("----> \(note.noteType): \(note.bg) at \(note.timeStamp)")
//            }
//        }
        showingDate = fromDate
        
        tableView.reloadData()
        
        if notes == nil || notes!.isEmpty {
            emptyViewLabel.isHidden = false
            
        } else {
            emptyViewLabel.isHidden = true
        }
    }
    
    var isShowingNotesOfToday: Bool {
        showingDate != nil && Calendar.current.isDateInToday(showingDate!)
    }
}

extension NotesViewController: UITableViewDelegate, UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        notes?.count ?? 0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let note = notes?[indexPath.row] else {
            fatalError("Should not be here")
        }
        
        let cell = tableView.dequeueReusableCell(withIdentifier: cellReuseIdentifier) as! NoteTableViewCell
        
        let noteType = NoteManager.NoteType(rawValue: Int(note.noteType))
        
        let typeIcon: UIImage?
        let typeIconColor: UIColor
        let backgroundColor: UIColor
        
        switch noteType {
        case .urgentHigh:
            typeIcon = R.image.ic_bg_high()?.withRenderingMode(.alwaysTemplate)
            typeIconColor = ConstantsUI.alertColor
            backgroundColor = ConstantsUI.alertColor.withAlphaComponent(0.15)
            
        case .high:
            typeIcon = R.image.ic_bg_high()?.withRenderingMode(.alwaysTemplate)
            typeIconColor = ConstantsUI.warningColor
            backgroundColor = .clear
            
        case .urgentLow:
            typeIcon = R.image.ic_bg_low()?.withRenderingMode(.alwaysTemplate)
            typeIconColor = ConstantsUI.alertColor
            backgroundColor = ConstantsUI.alertColor.withAlphaComponent(0.15)
            
        case .low:
            typeIcon = R.image.ic_bg_low()?.withRenderingMode(.alwaysTemplate)
            typeIconColor = ConstantsUI.warningColor
            backgroundColor = .clear
            
        case .fastDrop:
            typeIcon = R.image.ic_fastdrop()?.withRenderingMode(.alwaysTemplate)
            typeIconColor = ConstantsUI.alertColor
            backgroundColor = ConstantsUI.alertColor.withAlphaComponent(0.15)
            
        case .fastRise:
            typeIcon = R.image.ic_fastrise()?.withRenderingMode(.alwaysTemplate)
            typeIconColor = ConstantsUI.alertColor
            backgroundColor = ConstantsUI.alertColor.withAlphaComponent(0.15)
            
        default:
            typeIcon = R.image.ic_note_userinput()?.withRenderingMode(.alwaysTemplate)
            typeIconColor = .white
            backgroundColor = .clear
        }
        
        cell.typeIconImageView.image = typeIcon
        cell.tintColor = typeIconColor
        cell.backgroundColor = backgroundColor

        let isMgDl = UserDefaults.standard.bloodGlucoseUnitIsMgDl
        
        cell.bgLabel.text = note.bg.mgdlToMmolAndToString(mgdl: isMgDl)

        cell.bgUnitLabel.text = isMgDl ? Constants.bgUnitMgDl : Constants.bgUnitMmol
        cell.slopeLabel.text = BgReading.SlopeArrow(rawValue: Int(note.slopeArrow))?.description
        
        cell.contentLabel.text = note.noteContent
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "HH:mm"
        
        cell.timeStampLabel.text = dateFormatter.string(from: note.timeStamp)
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        65
    }
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

fileprivate class NoteTableViewCell: UITableViewCell {
    
    lazy var typeIconImageView: UIImageView = {
        UIImageView()
    }()
    
    lazy var bgLabel: UILabel = {
        let label = UILabel()
        label.font = .monospacedDigitSystemFont(ofSize: 35, weight: .light)
        label.textColor = .white
        return label
    }()
    
    lazy var slopeLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 18)
        label.textColor = .white
        return label
    }()
    
    lazy var bgUnitLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 12, weight: .light)
        label.textColor = .white
        return label
    }()
    
    lazy var contentLabel: UILabel = {
        let label = UILabel()
        label.textColor = .white
        return label
    }()
    
    lazy var timeStampLabel: UILabel = {
        let label = UILabel()
        label.textColor = .white
        label.font = .monospacedDigitSystemFont(ofSize: 14, weight: .regular)
        return label
    }()
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("Not implemented")
    }
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        contentView.addSubview(typeIconImageView)
        contentView.addSubview(bgLabel)
        contentView.addSubview(slopeLabel)
        contentView.addSubview(bgUnitLabel)
        contentView.addSubview(contentLabel)
        contentView.addSubview(timeStampLabel)
        
        typeIconImageView.snp.makeConstraints { make in
            make.size.equalTo(25)
            make.leading.equalToSuperview().offset(15)
            make.centerY.equalToSuperview()
        }
        
        bgLabel.snp.makeConstraints { make in
            make.leading.equalTo(typeIconImageView.snp.trailing).offset(10)
            make.centerY.equalToSuperview()
        }
        
        bgUnitLabel.snp.makeConstraints { make in
            make.leading.equalTo(bgLabel.snp.trailing).offset(5)
            make.bottom.equalTo(bgLabel).offset(-5)
        }
        
        slopeLabel.snp.makeConstraints { make in
            make.leading.equalTo(bgUnitLabel)
            make.bottom.equalTo(bgUnitLabel.snp.top)
        }
        
        contentLabel.snp.makeConstraints { make in
            make.leading.equalTo(bgLabel.snp.trailing).offset(70)
            make.centerY.equalToSuperview()
        }
        
        timeStampLabel.snp.makeConstraints { make in
            make.centerY.equalToSuperview()
            make.trailing.equalToSuperview().offset(-15)
        }
    }
}
