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
    
    func sheetWillDismiss() {
        
    }
}

class BottomSheet: UIView {
    
    private var contentView: BottomSheetContent?
    
    var tapOutsideToDismiss = true
    
    private let dimMask = UIView()

    init(sheetContent: BottomSheetContent) {
        contentView = sheetContent
        super.init(frame: .zero)
        
        sheetContent.bottomSheet = self
        setup()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setup() {
    }
    
    func dismissView() {
        contentView?.sheetWillDismiss()
        
        UIView.animate(withDuration: 0.3, animations: {
            self.dimMask.alpha = 0
            if let contentView = self.contentView {
                contentView.transform = CGAffineTransform(translationX: 0,
                                                          y: contentView.bounds.height)
            }

        }) { _ in
            self.removeFromSuperview()
            self.dimMask.removeFromSuperview()
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
    
    func show(in view: UIView, dimColor: UIColor = .black.withAlphaComponent(0.3)) {
        guard let contentView = contentView else {
            return
        }
        
        dimMask.backgroundColor = dimColor
        dimMask.alpha = 0
        
        isUserInteractionEnabled = true
        
        addSubview(dimMask)
        addSubview(contentView)
        view.addSubview(self)

        frame = view.bounds
        dimMask.frame = bounds
        
        contentView.snp.makeConstraints { (make) in
            make.leading.trailing.equalTo(self)
            make.bottom.equalTo(safeAreaLayoutGuide)
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.01) {
            contentView.transform = CGAffineTransform(translationX: 0, y: contentView.bounds.height)

            UIView.animate(withDuration: 0.3) {
                self.dimMask.alpha = 1.0
                contentView.transform = CGAffineTransform(translationX: 0, y: 0)
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
