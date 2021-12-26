//
//  BottomSheetDatePickerController.swift
//  xdrip
//
//  Created by Yuanbin Cai on 2021/12/26.
//  Copyright © 2021 Johan Degraeve. All rights reserved.
//

import UIKit

/// defines data typically available in a view that allows user to pick from a list : list of items, selected item, title, cancel lable, ok or add label, function to call when pressing cancel, function to call button when pressing add button
public class DatePickerData {
    private (set) var title: String?
    private (set) var subTitle: String?
    private (set) var datePickerMode: UIDatePicker.Mode
    private (set) var date: Date?
    private (set) var minimumDate: Date?
    private (set) var maximumDate: Date?
    private (set) var actionTitle: String?
    private (set) var actionHandler: ((_ date: Date) -> Void)
    private (set) var cancelHandler: (() -> Void)?
    private (set) var didSelectRowHandler: ((Int) -> Void)?
    
    public init(withTitle title: String?,
                withSubTitle subTitle: String?,
                datePickerMode: UIDatePicker.Mode,
                date: Date?,
                minimumDate: Date?,
                maximumDate: Date?,
                actionButtonText actionTitle: String?,
                onActionClick actionHandler: @escaping ((_ date: Date) -> Void),
                onCancelClick cancelHandler: (() -> Void)?,
                didSelectRowHandler: ((Int) -> Void)?) {
        self.title = title
        self.subTitle = subTitle
        self.datePickerMode = datePickerMode
        self.date = date
        self.minimumDate = minimumDate
        self.maximumDate = maximumDate
        self.actionTitle = actionTitle
        self.actionHandler = actionHandler
        self.cancelHandler = cancelHandler
        self.didSelectRowHandler = didSelectRowHandler
    }
}

public class DatePickerDataBuilder {
    
    private var title: String?
    private var subTitle: String?
    private var datePickerMode: UIDatePicker.Mode
    private var date: Date?
    private var minimumDate: Date?
    private var maximumDate: Date?
    private var actionTitle: String?
    private var actionHandler: ((_ date: Date) -> Void)
    private var cancelHandler: (() -> Void)?
    private var didSelectRowHandler: ((Int) -> Void)?
    
    public init(datePickerMode: UIDatePicker.Mode, actionHandler: @escaping ((_ date: Date) -> Void)) {
        self.datePickerMode = datePickerMode
        self.actionHandler = actionHandler
    }
    
    public func title(_ title: String?) -> DatePickerDataBuilder {
        self.title = title
        return self
    }
    
    public func subTitle(_ subTitle: String?) -> DatePickerDataBuilder {
        self.subTitle = subTitle
        return self
    }
    
    public func datePickerMode(_ datePickerMode: UIDatePicker.Mode) -> DatePickerDataBuilder {
        self.datePickerMode = datePickerMode
        return self
    }
    
    public func date(_ date: Date?) -> DatePickerDataBuilder {
        self.date = date
        return self
    }
    
    public func minimumDate(_ minimumDate: Date?) -> DatePickerDataBuilder {
        self.minimumDate = minimumDate
        return self
    }
    
    public func maximumDate(_ maximumDate: Date?) -> DatePickerDataBuilder {
        self.maximumDate = maximumDate
        return self
    }
    
    public func actionTitle(_ actionTitle: String?) -> DatePickerDataBuilder {
        self.actionTitle = actionTitle
        return self
    }
    
    public func cancelHandler(_ cancelHandler: (() -> Void)?) -> DatePickerDataBuilder {
        self.cancelHandler = cancelHandler
        return self
    }
    
    public func didSelectRowHandler(_ didSelectRowHandler: ((Int) -> Void)?) -> DatePickerDataBuilder {
        self.didSelectRowHandler = didSelectRowHandler
        return self
    }
    
    public func build() -> DatePickerData {
        return DatePickerData(withTitle: title,
                              withSubTitle: subTitle,
                              datePickerMode: datePickerMode,
                              date: date,
                              minimumDate: minimumDate,
                              maximumDate: maximumDate,
                              actionButtonText: actionTitle,
                              onActionClick: actionHandler,
                              onCancelClick: cancelHandler,
                              didSelectRowHandler: didSelectRowHandler)
    }
}

public class BottomSheetDatePickerController {
    
    public static func show(in viewController: UIViewController, datePickerData: DatePickerData) {
        let content = DatePickerContent(data: datePickerData)
        let sheet = SlideInSheet(sheetContent: content)
        
        if let view = viewController.tabBarController?.view {
            sheet.show(in: view, dimColor: .black.withAlphaComponent(0.5), slideInFrom: .bottom)
            
        } else {
            sheet.show(in: viewController.view, dimColor: .black.withAlphaComponent(0.5), slideInFrom: .bottom)
        }
    }
}

fileprivate class DatePickerContent: SlideInSheetContent {
    
    // maintitle on top of the pickerview
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 25)
        label.textColor = .white
        label.textAlignment = .center
        return label
    }()

    // subtitle on top of the pickerview
    private let subTitleLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 16)
        label.textColor = .lightText
        label.numberOfLines = 0
        label.lineBreakMode = NSLineBreakMode.byWordWrapping
        label.textAlignment = .center
        return label
    }()

    private let datePicker: UIDatePicker = {
        let picker = UIDatePicker()
        if #available(iOS 13.4, *) {
            picker.preferredDatePickerStyle = .wheels
        }
        
        picker.setValue(UIColor.white, forKeyPath: "textColor")
        picker.setValue(false, forKey: "highlightsToday")
        
        return picker
    }()

    private let actionButton: BetterButton = {
        let button = BetterButton()
        button.cornerRadius = 5
        button.bgColor = ConstantsUI.accentRed
        button.titleColor = .white
        button.titleFont = .systemFont(ofSize: 18)
        button.titleText = R.string.common.common_Ok()
        return button
    }()
    
    private var selectedRow = 0
    private var buttonDidClick = false
    
    private let data: DatePickerData
    
    init(data: DatePickerData) {
        self.data = data
        super.init(frame: .zero)
        initialize()
    }
    
    required init?(coder: NSCoder) {
        fatalError("Not implemented")
    }
    
    private func initialize() {
        // set actionTitle
        if let addButtonTitle = data.actionTitle {
            actionButton.titleText = addButtonTitle
        }
        
        datePicker.datePickerMode = data.datePickerMode
        if let date = data.date {
            datePicker.date = date
        }
        datePicker.minimumDate = data.minimumDate
        datePicker.maximumDate = data.maximumDate
        
        // set picker maintitle
        if let mainTitle = data.title {
            titleLabel.text = mainTitle
            
        } else {
            titleLabel.text = ""
        }
        
        // set title of pickerview
        if let subTitle = data.subTitle {
            subTitleLabel.text = subTitle
        }
        
        actionButton.addTarget(self, action: #selector(actionButtonDidClick(_:)), for: .touchUpInside)
            
        layout()
    }
    
    @objc private func actionButtonDidClick(_ button: UIControl) {
        buttonDidClick = true
        data.actionHandler(datePicker.date)
        sheet?.dismissView()
    }

    private func layout() {
        backgroundColor = ConstantsUI.mainBackgroundColor
        
        addSubview(titleLabel)
        addSubview(subTitleLabel)
        addSubview(datePicker)
        addSubview(actionButton)
        
        titleLabel.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview().inset(20)
        }
        
        subTitleLabel.snp.makeConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(10)
            make.leading.trailing.equalToSuperview().inset(20)
        }
        
        datePicker.snp.makeConstraints { make in
            make.top.equalTo(subTitleLabel.snp.bottom)
            make.width.centerX.equalToSuperview()
            make.height.equalTo(200)
            make.bottom.equalTo(actionButton.snp.top).offset(-10)
        }
        
        actionButton.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview().inset(10)
            make.height.equalTo(45)
        }
        
        snp.makeConstraints { make in
            make.top.equalTo(titleLabel).offset(-20)
            make.bottom.equalTo(actionButton).offset(10)
        }
    }
    
    override func sheetWillDismiss() {
        if !buttonDidClick {
            data.cancelHandler?()
        }
    }
}

//extension DatePickerContent: UIDatepikerdele {
//
//    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
//        return data.data[row]
//    }
//
//    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
//        // set selectedRow to row, value will be used when pickerview is closed
//        selectedRow = row
//
//        // call also didSelectRowHandler, if not nil, can be useful eg when pickerview contains list of sounds, sound can be played
//        data.didSelectRowHandler?(row)
//    }
//
//    func pickerView(_ pickerView: UIPickerView, rowHeightForComponent component: Int) -> CGFloat {
//        return 40
//    }
//}
