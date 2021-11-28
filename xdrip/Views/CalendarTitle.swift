//
//  CalendarTitle.swift
//  xdrip
//
//  Created by Yuanbin Cai on 2021/11/12.
//  Copyright © 2021 Johan Degraeve. All rights reserved.
//

import UIKit

protocol CalendarTitleDelegate: AnyObject {
    
    func calendarLeftButtonDidClick(_ calendarTitle: CalendarTitle, currentTime: Date)

    func calendarRightButtonDidClick(_ calendarTitle: CalendarTitle, currentTime: Date)
    
    func calendarTitleDidClick(_ calendarTitle: CalendarTitle)

}

class CalendarTitle: UIView {
    
    var dateTime: Date? {
        didSet {
            if let dateTime = dateTime {
                let dateFormatter = DateFormatter()
                dateFormatter.dateFormat = "yyyy-MM-dd"
                dateLabel.text = dateFormatter.string(from: dateTime)
                
            } else {
                dateLabel.text = "----------"
                showLeftArrow = false
                showRightArrow = false
            }
        }
    }
    
    var showLeftArrow: Bool = true {
        didSet {
            leftArrow.isHidden = !showLeftArrow
        }
    }
    
    var showRightArrow: Bool = true {
        didSet {
            rightArrow.isHidden = !showRightArrow
        }
    }
    
    weak var delegate: CalendarTitleDelegate?

    private let dateLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 20)
        label.textColor = .white
        label.text = "----------"
        return label
    }()
    
    private let leftArrow: UIButton = {
        let arrow = UIButton()
        arrow.setImage(R.image.ic_arrow_left(), for: .normal)
        return arrow
    }()
    
    private let rightArrow: UIButton = {
        let arrow = UIButton()
        arrow.setImage(R.image.ic_arrow_right(), for: .normal)
        return arrow
    }()
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        initialize()
    }
    
    init() {
        super.init(frame: .zero)
        initialize()
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        initialize()
    }
    
    private func initialize() {
        addSubview(dateLabel)
        addSubview(leftArrow)
        addSubview(rightArrow)
        
        dateLabel.snp.makeConstraints { make in
            make.center.equalToSuperview()        }
        
        leftArrow.snp.makeConstraints { make in
            make.centerY.equalToSuperview()
            make.right.equalTo(dateLabel.snp.left)
        }
        
        rightArrow.snp.makeConstraints { make in
            make.centerY.equalToSuperview()
            make.left.equalTo(dateLabel.snp.right)
        }
        
        snp.makeConstraints { make in
            make.top.equalTo(dateLabel)
            make.bottom.equalTo(dateLabel)
            make.left.equalTo(leftArrow)
            make.right.equalTo(rightArrow)
        }
        
        leftArrow.addTarget(self, action: #selector(buttonDidClick(_:)), for: .touchUpInside)
        rightArrow.addTarget(self, action: #selector(buttonDidClick(_:)), for: .touchUpInside)
    
        dateLabel.isUserInteractionEnabled = true
        dateLabel.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(titleDidClick(tap:))))
    }
    
    @objc private func buttonDidClick(_ button: UIButton) {
        if button == leftArrow {
            delegate?.calendarLeftButtonDidClick(self, currentTime: dateTime!)

        } else if button == rightArrow {
            delegate?.calendarRightButtonDidClick(self, currentTime: dateTime!)
        }
    }
    
    @objc private func titleDidClick(tap: UITapGestureRecognizer) {
        delegate?.calendarTitleDidClick(self)
    }
}
