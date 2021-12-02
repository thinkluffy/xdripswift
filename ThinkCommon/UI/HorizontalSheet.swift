//
//  HorizontalSheet.swift
//  xdrip
//
//  Created by Yuanbin Cai on 2021/12/2.
//  Copyright © 2021 Johan Degraeve. All rights reserved.
//

import UIKit

class HorizontalSheetContent: SwallowTouchesView {
    
    weak var sheet: HorizontalSheet?
    
}

class HorizontalSheet: UIView {

    enum SlideInFrom {
        case leading
        case trailing
    }
    
    var contentView: HorizontalSheetContent? {
        didSet {
            if let theContent = contentView {
                theContent.sheet = self
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
    
    func show(in view: UIView, dimColor: UIColor = .black.withAlphaComponent(0.3), from direction: SlideInFrom = .trailing) {
        guard let theContentView = contentView else {
            return
        }
        
        backgroundColor = dimColor
        
        isUserInteractionEnabled = true
        
        addSubview(theContentView)
        view.addSubview(self)

        frame = view.bounds
        
        theContentView.snp.makeConstraints { make in
            make.top.bottom.equalTo(self)
            if direction == .leading {
                make.leading.equalTo(safeAreaLayoutGuide)

            } else {
                make.trailing.equalTo(safeAreaLayoutGuide)
            }
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.01) {
            if direction == .leading {
                theContentView.transform = CGAffineTransform(translationX: -theContentView.bounds.width, y: 0)
                
            } else {
                theContentView.transform = CGAffineTransform(translationX: theContentView.bounds.width, y: 0)
            }
            
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
