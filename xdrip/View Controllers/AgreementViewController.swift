//
//  AgreementViewController.swift
//  xdrip
//
//  Created by Yuanbin Cai on 2021/12/22.
//  Copyright © 2021 Johan Degraeve. All rights reserved.
//

import UIKit

class AgreementViewController: UIViewController {

    private lazy var disclaimerLabel: UILabel = {
        let label = UILabel()
        label.textColor = .white
        label.font = .boldSystemFont(ofSize: 30)
        label.text = R.string.common.disclaimer()
        return label
    }()
    
    private lazy var contentTextView: UITextView = {
        let textView = UITextView()
        textView.backgroundColor = .clear
        textView.isSelectable = false
        
        let paraph = NSMutableParagraphStyle()
        paraph.lineSpacing = 16

        let attributes = [
            NSAttributedString.Key.font: UIFont.systemFont(ofSize: 18),
            NSAttributedString.Key.foregroundColor: UIColor.white,
            NSAttributedString.Key.paragraphStyle: paraph
        ]
        textView.attributedText = NSAttributedString(string: R.string.common.agreement(iOS.appDisplayName),
                                                     attributes: attributes)
        
        return textView
    }()
    
    private lazy var checkbox: Checkbox = {
        let checkbox = Checkbox()
        checkbox.isSelected = false
        checkbox.text = R.string.common.btn_understand_and_agree()
        checkbox.textColor = .white
        return checkbox
    }()
    
    private lazy var startToUseButton: BetterButton = {
        let button = BetterButton()
        button.titleText = R.string.common.start_to_use()
        button.titleColor = .white
        button.titleFont = .systemFont(ofSize: 18)
        button.bgColor = ConstantsUI.accentRed
        button.cornerRadius = 5
        button.isDisabled = true
        return button
    }()
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupView()
    }

    private func setupView() {
        view.backgroundColor = ConstantsUI.mainBackgroundColor

        view.addSubview(disclaimerLabel)
        
        let wrapperView = UIView()
        wrapperView.backgroundColor = ConstantsUI.contentBackgroundColor
        
        view.addSubview(wrapperView)
        wrapperView.addSubview(contentTextView)
        
        view.addSubview(checkbox)
        view.addSubview(startToUseButton)
        
        disclaimerLabel.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.top.equalTo(view.layoutMarginsGuide).offset(20)
        }
        
        wrapperView.snp.makeConstraints { make in
            make.top.equalTo(disclaimerLabel.snp.bottom).offset(20)
            make.leading.trailing.equalToSuperview()
            make.bottom.equalTo(checkbox.snp.top).offset(-10)
        }
        
        contentTextView.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(10)
        }
        
        checkbox.snp.makeConstraints { make in
            make.bottom.equalTo(startToUseButton.snp.top).offset(-10)
            make.centerX.equalToSuperview()
        }
        
        startToUseButton.snp.makeConstraints { make in
            make.height.equalTo(50)
            make.leading.bottom.trailing.equalTo(view.layoutMarginsGuide).inset(10)
        }

        checkbox.onSelectionStateDidChange() { [unowned self] checkbox, isSelected in
            self.startToUseButton.isDisabled = !isSelected
        }
        startToUseButton.addTarget(self, action: #selector(agreeButtonDidClick(_:)), for: .touchUpInside)
    }
    
    @objc private func agreeButtonDidClick(_ sender: UIControl) {
        if let initViewController = presentingViewController as? InitViewController {
            initViewController.agreementDidAgree()
        }
    }
}
