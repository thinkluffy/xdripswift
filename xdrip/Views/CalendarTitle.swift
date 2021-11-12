//
//  CalendarTitle.swift
//  xdrip
//
//  Created by Yuanbin Cai on 2021/11/12.
//  Copyright © 2021 Johan Degraeve. All rights reserved.
//

import UIKit

class CalendarTitle: UIView {

    var bgTime: Date? {
        didSet {
            if let bgTime = bgTime {
                let dateFormatter = DateFormatter()
                dateFormatter.dateFormat = "yyyy-MM-dd"
                dateLabel.text = dateFormatter.string(from: bgTime)
                
            } else {
                dateLabel.text = "----------"
            }
        }
    }
    
    private let dateLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 18)
        label.textColor = .white
        label.text = "----------"
        return label
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
     
        dateLabel.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.width.equalTo(100)
        }
    }
}
