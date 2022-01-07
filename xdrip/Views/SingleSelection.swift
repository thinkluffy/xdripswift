//
//  SingleSelection.swift
//  xdrip
//
//  Created by Yuanbin Cai on 2021/11/6.
//  Copyright © 2021 Johan Degraeve. All rights reserved.
//

import UIKit

class SingleSelectionItem: Equatable {
    
    let id: Int
    let title: String
    
    init(id: Int, title: String) {
        self.id = id
        self.title = title
    }
    
    static func == (lhs: SingleSelectionItem, rhs: SingleSelectionItem) -> Bool {
        lhs.id == rhs.id
    }
}

protocol SingleSelectionDelegate: AnyObject {
    
    func singleSelectionItemWillSelect(_ singleSelection: SingleSelection, item: SingleSelectionItem) -> Bool
    
    func singleSelectionItemDidSelect(_ singleSelection: SingleSelection, item: SingleSelectionItem)
}

class SingleSelection: UIStackView {
    
    private var items: [SingleSelectionItem]?
    private var idToItemView = [Int: ItemView]()
    
    weak var delegate: SingleSelectionDelegate?
    
    private (set) var selectedItem: SingleSelectionItem?
    
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
        spacing = 0
        alignment = .center
    }
    
    func show(items: [SingleSelectionItem]) {
        self.items = items
        self.idToItemView.removeAll()
        
        clearArrangedSubviews()
        
        for item in items {
            let v = ItemView(item: item)
            v.addGestureRecognizer(UITapGestureRecognizer(target: self,
                                                          action: #selector(itemViewDidClick(tap:))))
            idToItemView[item.id] = v
            
            addArrangedSubview(v)
        }
    }
    
    @objc private func itemViewDidClick(tap: UITapGestureRecognizer) {
        guard let itemView = tap.view as? ItemView else {
            return
        }
        
        guard itemView.item != selectedItem else {
            return
        }
        
        if delegate == nil || delegate!.singleSelectionItemWillSelect(self, item: itemView.item) {
            select(item: itemView.item)
        }
    }
    
    func select(id: Int, triggerCallback: Bool = true) {
        for view in arrangedSubviews {
            if let itemView = view as? ItemView {
                itemView.selected = false
            }
        }
        
        if let itemView = idToItemView[id] {
            itemView.selected = true
            selectedItem = itemView.item
            
            if triggerCallback {
                delegate?.singleSelectionItemDidSelect(self, item: itemView.item)
            }
        }
    }
    
    func select(item: SingleSelectionItem, triggerCallback: Bool = true) {
        select(id: item.id, triggerCallback: triggerCallback)
    }
}

fileprivate class ItemView: UIView {
    
    let item: SingleSelectionItem
    
    var selected = false {
        didSet {
            if selected {
                radioButton.image = R.image.ic_radio_button_on()?.withRenderingMode(.alwaysTemplate)
                radioButton.tintColor = ConstantsUI.accentRed
                title.textColor = ConstantsUI.accentRed
                
            } else {
                radioButton.image = R.image.ic_radio_button()?.withRenderingMode(.alwaysTemplate)
                radioButton.tintColor = .gray
                title.textColor = .white
            }
        }
    }
    
    private let radioButton: UIImageView = {
        let view = UIImageView()
        view.image = R.image.ic_radio_button()?.withRenderingMode(.alwaysTemplate)
        view.tintColor = .white
        return view
    }()
    
    private let title: UILabel = {
        let view = UILabel()
        view.textColor = .gray
        view.font = .systemFont(ofSize: 14)
        return view
    }()
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    init(item: SingleSelectionItem) {
        self.item = item
        super.init(frame: .zero)
        initialize()
    }
    
    private func initialize() {
        addSubview(radioButton)
        addSubview(title)
        
        radioButton.snp.makeConstraints { make in
            make.size.equalTo(25)
        }
        
        title.snp.makeConstraints { make in
            make.centerY.equalToSuperview()
            make.leading.equalTo(radioButton.snp.trailing)
        }
        
        snp.makeConstraints { make in
            make.top.bottom.leading.equalTo(radioButton)
            make.trailing.equalTo(title)
        }
        
        title.text = item.title
    }
}
