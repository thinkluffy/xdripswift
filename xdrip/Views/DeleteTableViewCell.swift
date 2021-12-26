//
//  DeleteTableViewCell.swift
//  xdrip
//
//  Created by Yuanbin Cai on 2021/12/26.
//  Copyright © 2021 Johan Degraeve. All rights reserved.
//

import UIKit

class DeleteTableViewCell: UITableViewCell {
    
    lazy var deleteLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 18)
        label.textColor = .white
        label.text = R.string.common.delete()
        return label
    }()
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("Not implemented")
    }
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        contentView.backgroundColor = ConstantsUI.accentRed
        
        contentView.addSubview(deleteLabel)
        
        deleteLabel.snp.makeConstraints { make in
            make.center.equalToSuperview()
        }
    }
}
