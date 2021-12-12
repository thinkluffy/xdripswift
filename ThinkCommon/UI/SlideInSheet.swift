//
//  HorizontalSheet.swift
//  xdrip
//
//  Created by Yuanbin Cai on 2021/12/2.
//  Copyright © 2021 Johan Degraeve. All rights reserved.
//

import UIKit

class SlideInSheetContent: SwallowTouchesView {
    
    weak var sheet: SlideInSheet?
    
    func sheetWillDismiss() {
        
    }
}

class SlideInSheet: UIView {

    enum SlideInFrom {
        case leading
        case trailing
        case top
        case bottom
    }
    
    var tapOutsideToDismiss = true
    
    private weak var parentView: UIView?
    private let dimMask = UIView()
    private var contentView: SlideInSheetContent?
    
    private var slideInFrom: SlideInFrom = .bottom
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    init(sheetContent: SlideInSheetContent) {
        contentView = sheetContent
        super.init(frame: .zero)
        
        sheetContent.sheet = self
        setup()
    }
    
    private func setup() {
    }
    
    func dismissView() {
        contentView?.sheetWillDismiss()

        UIView.animate(withDuration: 0.3, animations: {
            self.dimMask.alpha = 0
            if let contentView = self.contentView {
                switch self.slideInFrom {
                case .leading:
                    contentView.transform = CGAffineTransform(translationX: -contentView.bounds.width - iOS.safeAreaLeft,
                                                              y: 0)
                    break
                    
                case .trailing:
                    contentView.transform = CGAffineTransform(translationX: contentView.bounds.width + iOS.safeAreaRight,
                                                              y: 0)
                    break
                    
                case .top:
                    contentView.transform = CGAffineTransform(translationX: 0,
                                                              y: -contentView.bounds.height - iOS.safeAreaTop)
                    break
                    
                case .bottom:
                    contentView.transform = CGAffineTransform(translationX: 0,
                                                              y: contentView.bounds.height + iOS.safeAreaBottom)
                    break
                }
            }
            
        }) { _ in
            self.removeFromSuperview()
            self.dimMask.removeFromSuperview()
            self.contentView?.removeFromSuperview()
            self.isUserInteractionEnabled = false
            self.contentView = nil
            self.parentView = nil
        }
    }
    
    @objc private func tapOutside() {
        if tapOutsideToDismiss {
            dismissView()
        }
    }
    
    func show(in view: UIView,
              dimColor: UIColor = .black.withAlphaComponent(0.3),
              slideInFrom: SlideInFrom) {
        guard let contentView = contentView else {
            return
        }
        
        self.slideInFrom = slideInFrom
        parentView = view
        
        dimMask.backgroundColor = dimColor
        dimMask.alpha = 0
        
        isUserInteractionEnabled = true
        
        addSubview(dimMask)
        addSubview(contentView)
        view.addSubview(self)

        frame = view.bounds
        dimMask.frame = bounds

        contentView.snp.makeConstraints { make in
            switch slideInFrom {
            case .leading:
                make.leading.equalTo(safeAreaLayoutGuide)
                make.top.bottom.equalTo(self)
                break
                
            case .trailing:
                make.trailing.equalTo(safeAreaLayoutGuide)
                make.top.bottom.equalTo(self)
                break
                
            case .top:
                make.leading.trailing.equalTo(self)
                make.top.equalTo(safeAreaLayoutGuide)
                break
                
            case .bottom:
                make.leading.trailing.equalTo(self)
                make.bottom.equalTo(safeAreaLayoutGuide)
                break
            }
        }

        DispatchQueue.main.async {
            switch slideInFrom {
            case .leading:
                contentView.transform = CGAffineTransform(translationX: -contentView.bounds.width - iOS.safeAreaLeft,
                                                          y: 0)
                break
                 
            case .trailing:
                contentView.transform = CGAffineTransform(translationX: contentView.bounds.width + iOS.safeAreaRight,
                                                          y: 0)
                break
                
            case .top:
                contentView.transform = CGAffineTransform(translationX: 0,
                                                          y: -contentView.bounds.height - iOS.safeAreaTop)
                break
                
            case .bottom:
                contentView.transform = CGAffineTransform(translationX: 0,
                                                          y: contentView.bounds.height + iOS.safeAreaBottom)
                break
            }
            
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
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        if let parentView = parentView {
            frame = parentView.bounds
            dimMask.frame = bounds
        }
    }
}
