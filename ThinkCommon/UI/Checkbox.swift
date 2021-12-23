//
//  Checkbox.swift
//  xdrip
//
//  Created by Yuanbin Cai on 2021/12/22.
//  Copyright © 2021 Johan Degraeve. All rights reserved.
//

import UIKit

@IBDesignable
public class Checkbox: UIView {

    @IBInspectable
    public var isSelected: Bool = false {
        didSet {
            if isSelected {
                checkmark.image = selectedCheckmarkImage
                
            } else {
                checkmark.image = notSelectedCheckmarkImage
            }
        }
    }
    
    @IBInspectable
    public var text: String? {
        didSet {
            textLabel.text = text
            invalidateIntrinsicContentSize()
        }
    }
    
    @IBInspectable
    public var textColor: UIColor = .darkText {
        didSet {
            textLabel.textColor = textColor
        }
    }
    
    @IBInspectable
    public var textFont: UIFont = .systemFont(ofSize: 16) {
        didSet {
            textLabel.font = textFont
            invalidateIntrinsicContentSize()
        }
    }
    
    @IBInspectable
    public var checkmarkColor: UIColor = .white {
        didSet {
            checkmark.tintColor = checkmarkColor
        }
    }
    
    private lazy var checkmark: UIImageView = {
        let imageView = UIImageView()
        imageView.image = notSelectedCheckmarkImage
        return imageView
    }()
    
    private lazy var textLabel: UILabel = {
        let label = UILabel()
        label.font = textFont
        label.textColor = textColor
        return label
    }()
    
    private lazy var selectedCheckmarkImage: UIImage? = {
        UIImage(named: "ic_checkbox_h")
    }()
    
    private lazy var notSelectedCheckmarkImage: UIImage? = {
        UIImage(named: "ic_checkbox")
    }()
    
    private var selectionStateDidChangeCallback: ((_ checkbox: Checkbox, _ newSelection: Bool) -> Void)?
    
    init() {
        super.init(frame: .zero)
        initialize()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        initialize()
    }
    
    private func initialize() {
        addSubview(checkmark)
        addSubview(textLabel)
        
        checkmark.snp.makeConstraints { make in
            make.centerY.equalToSuperview()
            make.size.equalTo(30)
        }
        
        textLabel.snp.makeConstraints { make in
            make.leading.equalTo(checkmark.snp.trailing).offset(10)
            make.centerY.equalToSuperview()
        }
        
        snp.makeConstraints { make in
            make.leading.equalTo(checkmark)
            make.trailing.equalTo(textLabel)
            make.top.bottom.equalTo(checkmark)
        }
        
        addGestureRecognizer(UITapGestureRecognizer(target: self,
                                                    action: #selector(viewDidClick(tap:))))
    }
    
    public override var intrinsicContentSize: CGSize {
        CGSize(width: checkmark.intrinsicContentSize.width + 10 + textLabel.intrinsicContentSize.width,
               height: max(checkmark.intrinsicContentSize.height, textLabel.intrinsicContentSize.height))
    }
    
    public func onSelectionStateDidChange(_ selectionStateDidChangeCallback: @escaping (_ checkbox: Checkbox, _ newSelection: Bool) -> Void) {
        self.selectionStateDidChangeCallback = selectionStateDidChangeCallback
    }
    
    @objc private func viewDidClick(tap: UITapGestureRecognizer) {
        isSelected = !isSelected
        selectionStateDidChangeCallback?(self, isSelected)
    }
    
    public override func prepareForInterfaceBuilder() {
        initialize()
        text = "Some cool text goes here"
    }
}
