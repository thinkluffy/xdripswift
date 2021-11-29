//
//  BottomSheet.swift
//  Paintist
//
//  Created by Yuanbin Cai on 2020/4/24.
//  Copyright © 2020 thinkyeah. All rights reserved.
//

import UIKit

class BottomSheetContent: SwallowTouchesView {
    
    weak var bottomSheet: BottomSheet?
    
}

class BottomSheet: UIView {
    
    var contentView: BottomSheetContent? {
        didSet {
            if let theContent = contentView {
                theContent.bottomSheet = self
            }
        }
    }
    
    var tapOutsideToDismiss = true
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setup() {
        backgroundColor = UIColor(red: 0, green: 0, blue: 0, alpha: 0.3)
        alpha = 0
    }
    
    func dismissView() {
        UIView.animate(withDuration: 0.3, animations: {
            self.alpha = 0
        }) { _ in
            self.removeFromSuperview()
            self.contentView?.removeFromSuperview()
            self.isUserInteractionEnabled = false
            self.contentView = nil
        }
    }
    
    @objc private func tapOutside() {
        if tapOutsideToDismiss {
            dismissView()
        }
    }
    
    func show(in view: UIView){
        guard let theContentView = contentView else {
            return
        }
        
        isUserInteractionEnabled = true
        
        addSubview(theContentView)
        view.addSubview(self)

        frame = view.bounds
        
        theContentView.snp.makeConstraints { (make) in
            make.width.centerX.equalTo(self)
            make.bottom.equalTo(self)
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.01) {
            theContentView.transform = CGAffineTransform(translationX: 0, y: theContentView.bounds.height)

            UIView.animate(withDuration: 0.3) {
                self.alpha = 1.0
                theContentView.transform = CGAffineTransform(translationX: 0, y: 0)
            }
        }
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesEnded(touches, with: event)
        if tapOutsideToDismiss {
            dismissView()
        }
    }
}
