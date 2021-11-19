//
//  SingleSelection.swift
//  xdrip
//
//  Created by Yuanbin Cai on 2021/11/6.
//  Copyright © 2021 Johan Degraeve. All rights reserved.
//

import UIKit

class SingleSelectionItem {
    
    let title: String
    
    init(title: String) {
        self.title = title
    }
}

class SingleSelection: UIStackView {
    
    private var items: [SingleSelectionItem]!

    required init(coder: NSCoder) {
        super.init(coder: coder)
        initialize()
    }
    
    init() {
        super.init(frame: .zero)
        initialize()
    }
    
    private func initialize() {
        distribution = .fillEqually
        axis = .horizontal
        spacing = 10
        alignment = .center
    }
    
    func show(items: [SingleSelectionItem]) {
        self.items = items
        
        clearArrangedSubviews()
        
        for item in items {
            let itemView = ItemView()
            addArrangedSubview(itemView)
        }
    }
}

fileprivate class ItemView: UIView {
    
    private let radioButton: UIImageView = {
        let view = UIImageView()
        return view
    }()
    
    private let title: UILabel = {
        let view = UILabel()
        return view
    }()
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    init() {
        super.init(frame: .zero)
        initialize()
    }
    
    private func initialize() {
        addSubview(radioButton)
        addSubview(title)
        
        title.snp.makeConstraints { make in
            make.centerY.equalToSuperview()
            make.leading.equalTo(radioButton.snp.trailing).offset(10)
        }
        
        snp.makeConstraints { make in
            make.top.bottom.leading.equalTo(radioButton)
            make.trailing.equalTo(title)
        }
    }
}
