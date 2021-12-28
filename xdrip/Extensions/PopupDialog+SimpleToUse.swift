//
//  PopupDialog.swift
//  xdrip
//
//  Created by Yuanbin Cai on 2021/12/17.
//  Copyright © 2021 Johan Degraeve. All rights reserved.
//

import UIKit
import PopupDialog

extension PopupDialog {

    convenience init(title: String?,
                     message: String?,
                     actionTitle: String = R.string.common.common_Ok(),
                     actionHandler: (() -> Void)?,
                     cancelTitle: String? = nil,
                     cancelHandler: (() -> Void)? = nil,
                     dismissHandler: (() -> Void)? = nil) {
        self.init(title: title,
                  message: message,
                  buttonAlignment: .horizontal,
                  transitionStyle: .iOS,
                  tapGestureDismissal: false,
                  panGestureDismissal: false,
                  completion: dismissHandler)
        
        let actionButton = DefaultButton(title: actionTitle) {
            if let actionHandler = actionHandler {
                actionHandler()
            }
        }
        addButton(actionButton)
        
        if let cancelTitle = cancelTitle {
            let cancelButton = CancelButton(title: cancelTitle) {
                if let cancelHandler = cancelHandler {
                    cancelHandler()
                }
            }
            addButton(cancelButton)
        }
    }
    
    convenience init(title: String?,
                     message: String?,
                     keyboardType: UIKeyboardType?,
                     text: String?,
                     placeHolder: String?,
                     actionTitle: String = R.string.common.common_Ok(),
                     dismissOnActionButtonTap: Bool = true,
                     actionHandler: @escaping ((_ dialog: PopupDialog, _ text: String) -> Void),
                     cancelTitle: String = R.string.common.common_cancel(),
                     cancelHandler: (() -> Void)? = nil) {
        
        let inputViewController = PopupDialogInputViewController(
            title: title,
            message: message,
            keyboardType: keyboardType ?? .default,
            text: text,
            placeHolder: placeHolder
        )
        
        self.init(viewController: inputViewController,
                  buttonAlignment: .horizontal,
                  transitionStyle: .iOS,
                  tapGestureDismissal: false,
                  panGestureDismissal: false)
        
        let actionButton = DefaultButton(title: actionTitle, dismissOnTap: dismissOnActionButtonTap) {
            if let inputText = inputViewController.inputText {
                actionHandler(self, inputText)
            }
        }
        addButton(actionButton)
        
        let cancelButton = CancelButton(title: cancelTitle) {
            if let cancelHandler = cancelHandler {
                cancelHandler()
            }
        }
        addButton(cancelButton)
    }
}

fileprivate class PopupDialogInputView: UIView {
    
    var inputText: String? {
        textField.text
    }
    
    private lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.font = .boldSystemFont(ofSize: 18)
        label.textColor = .white
        label.textAlignment = .center
        return label
    }()
    
    private lazy var messageLabel: UILabel = {
        let label = UILabel()
        label.font  = .systemFont(ofSize: 14)
        label.textColor = .white.withAlphaComponent(0.8)
        label.textAlignment = .center
        return label
    }()
    
    lazy var textField: UITextField = {
        let textField = UITextField()
        textField.textColor = .white
        return textField
    }()
    
    required init?(coder: NSCoder) {
        fatalError("Not implemented")
    }
    
    init(title: String?,
         message: String?,
         keyboardType: UIKeyboardType,
         text: String?,
         placeHolder: String?) {
        
        super.init(frame: .zero)
        initialize()
        
        titleLabel.text = title
        messageLabel.text = message
        textField.keyboardType = keyboardType
        textField.text = text
        if let placeHolder = placeHolder {
            textField.attributedPlaceholder = NSAttributedString(
                string: placeHolder,
                attributes: [NSAttributedString.Key.foregroundColor: UIColor.white.withAlphaComponent(0.6)]
            )
        }
    }
    
    private func initialize() {
        addSubview(titleLabel)
        addSubview(messageLabel)
        
        let textFieldWrap = Card()
        textFieldWrap.backgroundColor = ConstantsUI.contentBackgroundColor
        
        addSubview(textFieldWrap)
        textFieldWrap.addSubview(textField)

        titleLabel.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview().inset(10)
        }
        
        messageLabel.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview().inset(10)
            make.top.equalTo(titleLabel.snp.bottom).offset(5)
        }
        
        textFieldWrap.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview().inset(20)
            make.top.equalTo(messageLabel.snp.bottom).offset(20)
            make.height.equalTo(40)
        }
        
        textField.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(10)
        }
        
        snp.makeConstraints { make in
            make.top.equalTo(titleLabel).offset(-30)
            make.bottom.equalTo(textFieldWrap).offset(20)
        }
    }
}

fileprivate class PopupDialogInputViewController: UIViewController {

    private let popupDialogInputView: PopupDialogInputView
    
    var inputText: String? {
        popupDialogInputView.inputText
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    init(title: String?,
         message: String?,
         keyboardType: UIKeyboardType,
         text: String?,
         placeHolder: String?) {
        
        popupDialogInputView = PopupDialogInputView(
            title: title,
            message: message,
            keyboardType: keyboardType,
            text: text,
            placeHolder: placeHolder
        )
        
        super.init(nibName: nil, bundle: nil)
        
        popupDialogInputView.textField.delegate = self
    }
    
    override public func loadView() {
        super.loadView()
        view = popupDialogInputView
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        popupDialogInputView.textField.becomeFirstResponder()
    }
    
    @objc func endEditing() {
        view.endEditing(true)
    }
}

extension PopupDialogInputViewController: UITextFieldDelegate {

    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        endEditing()
        return true
    }
}
