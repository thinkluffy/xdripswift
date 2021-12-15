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
            
            switch type {
            case .Libre2Type, .MiaoMiaoType, .BubbleType, .BluconType, .BlueReaderType, .DropletType, .GNSentryType, .WatlaaType, .AtomType:
                image = R.image.libre()

            case .DexcomG6Type:
                image = R.image.dexcomG6()
                
            case .DexcomG5Type:
                image = R.image.dexcomG5()
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
