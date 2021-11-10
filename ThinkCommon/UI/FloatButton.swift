//
//  FloatButton.swift
//  Paintist
//
//  Created by Yuanbin Cai on 2020/4/28.
//  Copyright © 2020 thinkyeah. All rights reserved.
//

import UIKit

protocol FloatButtonDelegate: AnyObject {
    
    func buttonDidClick(_ floatButton: FloatButton, clickedButton: UIButton, id: Int)
}

class FloatButton: RoundedButton {
    
    private var subButtons = [RoundedButton]()
    private let masker = UIControl()
    
    private var expanded = false
    private var animating = false
    
    weak var delegate: FloatButtonDelegate?
    
    override init(bgColor: UIColor? = .white, withShadow: Bool = false) {
        super.init(bgColor: bgColor, withShadow: withShadow)
        masker.translatesAutoresizingMaskIntoConstraints = false

        addTarget(self, action: #selector(didTap), for: .touchUpInside)
        masker.addTarget(self, action: #selector(didTapMaster), for: .touchUpInside)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func addItem(id: Int, icon: UIImage) {
        let subButton = RoundedButton(withShadow: self.withShadow)
        subButton.setImage(icon, for: .normal)
        subButton.tag = id
        subButton.addTarget(self, action: #selector(didTapSubbutton(_:)), for: .touchUpInside)
        subButtons.append(subButton)
    }
    
    @objc private func didTapSubbutton(_ subbutton: RoundedButton) {
        delegate?.buttonDidClick(self, clickedButton: subbutton, id: subbutton.tag)
    }
    
    @objc private func didTapMaster() {
        guard !animating else {
            return
        }
        shrink()
    }
    
    @objc private func didTap() {
        guard !animating else {
            return
        }
        
        if expanded {
            shrink()
            
        } else {
            expand()
        }
    }
    
    func expand() {
        guard let sv = superview else {
            return
        }
        
        animating = true
        masker.frame = sv.bounds
        sv.addSubview(masker)
        
        for btn in subButtons {
            masker.addSubview(btn)
            btn.frame = frame
            btn.alpha = 0
        }
        
        UIView.animate(withDuration: 0.2, animations: {
            for (i, btn) in self.subButtons.enumerated() {
                btn.frame.origin.y += (self.bounds.size.height + 10) * CGFloat(i + 1)
                btn.alpha = 1
            }
            
            let radians = 135 / 180.0 * CGFloat.pi
            let rotation = self.transform.rotated(by: radians)
            self.transform = rotation
            
        }, completion: { (finished) in
            self.animating = false
            self.expanded = true
        })
    }
    
    func shrink() {
        animating = true
        
        UIView.animate(withDuration: 0.2, animations: {
            for btn in self.subButtons {
                btn.frame.origin.y = self.frame.origin.y
                btn.alpha = 0
            }
            
            let radians = -135 / 180.0 * CGFloat.pi
            let rotation = self.transform.rotated(by: radians)
            self.transform = rotation
            
        }, completion: { finished in
            for btn in self.subButtons {
                btn.removeFromSuperview()
            }
            self.masker.removeFromSuperview()
            self.animating = false
            self.expanded = false
        })
    }
}
