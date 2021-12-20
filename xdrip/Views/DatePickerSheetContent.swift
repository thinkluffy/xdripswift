//
//  DatePickerSheetContent.swift
//  xdrip
//
//  Created by Yuanbin Cai on 2021/12/18.
//  Copyright © 2021 Johan Degraeve. All rights reserved.
//

import UIKit
import FSCalendar

protocol DatePickerSheetContentDelegate: AnyObject {
    
    func datePickerSheetContent(_ sheetContent: DatePickerSheetContent, didSelect date: Date)
}

class DatePickerSheetContent: SlideInSheetContent {
    
    weak var delegate: DatePickerSheetContentDelegate?
        
    private let selectedDate: Date?
    private let slideInFrom: SlideInSheet.SlideInFrom
    
    init(selectedDate: Date, slideInFrom: SlideInSheet.SlideInFrom) {
        self.selectedDate = selectedDate
        self.slideInFrom = slideInFrom
        super.init(frame: .zero)
        initialize()
    }
    
    required init?(coder: NSCoder) {
        fatalError("Not supported")
    }
    
    private func initialize() {
        backgroundColor = ConstantsUI.mainBackgroundColor
        
        let calendar = FSCalendar()
        calendar.appearance.headerTitleColor = .white
        calendar.appearance.headerDateFormat = "yyyy-MM"
        calendar.appearance.headerMinimumDissolvedAlpha = 0
        calendar.appearance.titleDefaultColor = .white
        calendar.appearance.weekdayTextColor = .white
        calendar.appearance.todayColor = ConstantsUI.contentBackgroundColor
        calendar.appearance.todaySelectionColor = ConstantsUI.accentRed
        calendar.appearance.selectionColor = ConstantsUI.accentRed
        
        if let selectedDate = selectedDate {
            calendar.select(selectedDate)
        }
            
        calendar.delegate = self
        
        addSubview(calendar)

        snp.makeConstraints { make in
            switch slideInFrom {
            case .leading, .trailing:
                make.width.equalTo(320)
            case .top, .bottom:
                make.height.equalTo(320)
            }
        }
        
        calendar.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(10)
        }
    }
}

extension DatePickerSheetContent: FSCalendarDelegate {
    
    // avoid selecting a date in future
    func calendar(_ calendar: FSCalendar, shouldSelect date: Date, at monthPosition: FSCalendarMonthPosition) -> Bool {
        date <= Date()
    }
    
    func calendar(_ calendar: FSCalendar, didSelect date: Date, at monthPosition: FSCalendarMonthPosition) {
        delegate?.datePickerSheetContent(self, didSelect: date)
    }
}
