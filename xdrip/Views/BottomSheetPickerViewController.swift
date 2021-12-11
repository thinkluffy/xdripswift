//
//  BottomSheetPickerViewController.swift
//  xdrip
//
//  Created by Yuanbin Cai on 2021/12/10.
//  Copyright © 2021 Johan Degraeve. All rights reserved.
//

import UIKit

/// defines data typically available in a view that allows user to pick from a list : list of items, selected item, title, cancel lable, ok or add label, function to call when pressing cancel, function to call button when pressing add button
public class PickerViewData {
    var title: String?
    var subTitle: String?
    var data: [String]
    var selectedRow: Int
    var actionTitle: String?
    var cancelTitle: String?
    var actionHandler: ((_ index: Int) -> Void)
    var cancelHandler: (() -> Void)?
    var didSelectRowHandler: ((Int) -> Void)?
    var priority: PickerViewPriority?
    
    /// initializes PickerViewData.
    /// - parameters:
    ///     - withMainTitle : if present, then a larger sized main title must be shown on top of the picker, example "High Alert" must be shown in bigger font
    ///     - withSubTitle : example "Select Snooze Period" , can be in smaller font
    ///     - withData : list of strings to select from
    ///     - selectedRow : default selected row in withData
    ///     - actionButtonText : text to show in the ok button, eg "Ok" or "Add"
    ///     - cancelButtonText : text to show in the cancel button, eg "Cancel"
    ///     - onActionClick : closure to run when user clicks the actionButton
    ///     - onCancelClick : closure to run when user clicks the cancelButton
    ///     - didSelectRowHandler  : closure to run when user selects a row, even before clicking ok or cancel. Can be useful eg to play a sound
    init(withTitle title: String?,
         withSubTitle subTitle: String?,
         withData data: [String],
         selectedRow: Int?,
         withPriority priority: PickerViewPriority?,
         actionButtonText actionTitle: String?,
         cancelButtonText cancelTitle: String?,
         onActionClick actionHandler: @escaping ((_ index: Int) -> Void),
         onCancelClick cancelHandler: (() -> Void)?,
         didSelectRowHandler:((Int) -> Void)?) {
        self.title = title
        self.subTitle = subTitle
        self.data = data
        self.selectedRow = selectedRow != nil ? selectedRow!: 0
        self.actionTitle = actionTitle
        self.cancelTitle = cancelTitle
        self.actionHandler = actionHandler
        self.cancelHandler = cancelHandler
        self.didSelectRowHandler = didSelectRowHandler
        self.priority = priority
    }
}

/// priority to apply in the pickerview. High can use other colors and or size, Up to the pickerview
public enum PickerViewPriority {
    case normal
    case high
}

public class BottomSheetPickerViewController {
    
    public static func show(in viewController: UIViewController, pickerViewData: PickerViewData) {
        let content = PickerViewContent(data: pickerViewData)
        let sheet = BottomSheet(sheetContent: content)
        
        if let view = viewController.tabBarController?.view {
            sheet.show(in: view, dimColor: .black.withAlphaComponent(0.5))
            
        } else {
            sheet.show(in: viewController.view, dimColor: .black.withAlphaComponent(0.5))
        }
    }
}

fileprivate class PickerViewContent: BottomSheetContent {
    
    // maintitle on top of the pickerview
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 25)
        label.textColor = .white
        return label
    }()

    // subtitle on top of the pickerview
    private let subTitleLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 16)
        label.textColor = .lightText
        return label
    }()

    private let pickerView: UIPickerView = {
        let view = UIPickerView()
        view.setValue(UIColor.white, forKeyPath: "textColor")
        return view
    }()

    private let actionButton: BetterButton = {
        let button = BetterButton()
        button.cornerRadius = 5
        button.bgColor = ConstantsUI.accentRed
        button.titleColor = .white
        button.titleFont = .systemFont(ofSize: 20)
        button.titleText = R.string.common.common_Ok()
        return button
    }()
    
    private var selectedRow = 0
    private var buttonDidClick = false
    
    private let data: PickerViewData
    
    init(data: PickerViewData) {
        self.data = data
        super.init(frame: .zero)
        initialize()
    }
    
    required init?(coder: NSCoder) {
        fatalError("Not implemented")
    }
    
    private func initialize() {
        //data source
        pickerView.dataSource = self
        
        //delegate
        pickerView.delegate = self

        //set actionTitle
        if let addButtonTitle = data.actionTitle {
            actionButton.titleText = addButtonTitle
        }
        
        // set selectedRow
        selectedRow = data.selectedRow
        pickerView.selectRow(data.selectedRow, inComponent: 0, animated: false)
        
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
        
        /// TODO:- the actual color to be used should be defined somewhere else
        // if priority defined then if high priority, apply other color
        if let priority = data.priority {
            switch priority {
                
            case .normal:
                break
            case .high:
                titleLabel.textColor = ConstantsUI.accentRed
            }
        }
        
        actionButton.addTarget(self, action: #selector(actionButtonDidClick(_:)), for: .touchUpInside)
            
        layout()
    }
    
    @objc private func actionButtonDidClick(_ button: UIControl) {
        buttonDidClick = true
        data.actionHandler(self.selectedRow)
        bottomSheet?.dismissView()
    }

    private func layout() {
        let container = UIView()
        container.backgroundColor = ConstantsUI.mainBackgroundColor
        
        addSubview(container)
        container.addSubview(titleLabel)
        container.addSubview(subTitleLabel)
        container.addSubview(pickerView)
        container.addSubview(actionButton)
        
        container.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        
        titleLabel.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(20)
            make.centerX.equalToSuperview()
        }
        
        subTitleLabel.snp.makeConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(10)
            make.centerX.equalToSuperview()
        }
        
        pickerView.snp.makeConstraints { make in
            make.top.equalTo(subTitleLabel.snp.bottom)
            make.width.centerX.equalToSuperview()
            make.height.equalTo(200)
            make.bottom.equalTo(actionButton.snp.top).offset(-10)
        }
        
        actionButton.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview().inset(10)
            make.bottom.equalToSuperview().offset(-10)
            make.height.equalTo(50)
        }
    }
    
    override func sheetWillDismiss() {
        if !buttonDidClick {
            data.cancelHandler?()
        }
    }
}

extension PickerViewContent: UIPickerViewDelegate {
          
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return data.data[row]
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        // set selectedRow to row, value will be used when pickerview is closed
        selectedRow = row
        
        // call also didSelectRowHandler, if not nil, can be useful eg when pickerview contains list of sounds, sound can be played
        data.didSelectRowHandler?(row)
    }
    
    func pickerView(_ pickerView: UIPickerView, rowHeightForComponent component: Int) -> CGFloat {
        return 40
    }
}

extension PickerViewContent: UIPickerViewDataSource {
          
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return data.data.count
    }
}
