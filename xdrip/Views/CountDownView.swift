//
//  CountDownView.swift
//  xdrip
//
//  Created by Yuanbin Cai on 2021/11/30.
//  Copyright © 2021 Johan Degraeve. All rights reserved.
//

import UIKit

class CountDownView: UIView {

    private lazy var countDownLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 16)
        label.textColor = .white
        return label
    }()
    
    private var tick = 60
    
    private var timer: Timer?
    
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
        addSubview(countDownLabel)
        
        countDownLabel.snp.makeConstraints { make in
            make.center.equalToSuperview()
        }
    }
    
    func reset(to seconds: Int) {
        stopCountCown()
        
        tick = seconds
        countDownLabel.text = "\(tick) s"
    }
    
    func startCountDown() {
        if timer != nil {
            timer?.invalidate()
        }
        
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] timer in
            guard let self = self else {return}
            
            self.tick -= 1
            if self.tick < 0 {
                timer.invalidate()
                self.countDownLabel.text = nil

            } else {
                self.countDownLabel.text = "\(self.tick) s"
            }
        }
    }
    
    func stopCountCown() {
        if timer != nil {
            timer?.invalidate()
            timer = nil
        }
    }
}
