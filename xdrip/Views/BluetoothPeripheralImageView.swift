//
//  BluetoothPeripheralImageView.swift
//  xdrip
//
//  Created by Yuanbin Cai on 2021/12/10.
//  Copyright © 2021 Johan Degraeve. All rights reserved.
//

import UIKit

class BluetoothPeripheralImageView: UIImageView {

    var bluetoothPeripheralType: BluetoothPeripheralType? {
        didSet {
            guard let type = bluetoothPeripheralType else {
                // todo: set the default image
                image = nil
                return
            }
            
            if type == .Libre2Type {
                image = R.image.libre()
                
            } else if type == .DexcomG6Type {
                image = R.image.dexcomG6()
                
            } else {
                image = R.image.libre()
            }
        }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        initialize()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        initialize()
    }
    
    private func initialize() {
        contentMode = .scaleAspectFit
    }
}
