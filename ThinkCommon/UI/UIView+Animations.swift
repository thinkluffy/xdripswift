//
//  UIView+Animations.swift
//  Paintist
//
//  Created by Yuanbin Cai on 2020/5/9.
//  Copyright © 2020 thinkyeah. All rights reserved.
//

import UIKit

extension UIView {

    func bounce(repeatCount: Float = 2, duration: CFTimeInterval = 0.06, strength: Float = 1.2) {
        let animation = CABasicAnimation(keyPath: "transform.scale")
        animation.duration = duration
        animation.repeatCount = Float(repeatCount)
        animation.autoreverses = true
        animation.fromValue = 1
        animation.toValue = strength
        layer.add(animation, forKey: animation.keyPath)
    }
    
    func shake(repeatCount: Float = 4, duration: CFTimeInterval = 0.06) {
        let midX = center.x
        let midY = center.y

        let animation = CABasicAnimation(keyPath: "position")
        animation.duration = duration
        animation.repeatCount = Float(repeatCount)
        animation.autoreverses = true
        animation.fromValue = CGPoint(x: midX - 5, y: midY)
        animation.toValue = CGPoint(x: midX + 5, y: midY)
        layer.add(animation, forKey: animation.keyPath)
    }
    
    func zoomTo(_ targetView: UIView, duration: CFTimeInterval = 0.5, completion: (() -> Void)? = nil) {
        UIView.animate(withDuration: duration, animations: {
            self.transform = CGAffineTransform.identity.scaledBy(x: targetView.bounds.width / self.bounds.width,
                                                                 y: targetView.bounds.height / self.bounds.height)
            
        }) { _ in
            completion?()
        }
    }
    
    func zoomOut(duration: CFTimeInterval = 0.5, completion: (() -> Void)? = nil) {
        UIView.animate(withDuration: duration, animations: {
            self.transform = CGAffineTransform.identity.scaledBy(x: 0.001, y: 0.001)
            
        }) { _ in
            completion?()
        }
    }
    
    func zoomIn(duration: CFTimeInterval = 0.5, completion: (() -> Void)? = nil) {
        self.transform = CGAffineTransform.identity.scaledBy(x: 0.001, y: 0.001)
        UIView.animate(withDuration: duration, animations: {
            self.transform = CGAffineTransform.identity.scaledBy(x: 1, y: 1)
            
        }) { _ in
            completion?()
        }
    }
    
    func wobble(repeatCount: Float = 2, duration: CFTimeInterval = 0.4) {
        let animation = CABasicAnimation(keyPath: "transform.rotation")
        animation.duration = duration
        animation.repeatCount = Float(repeatCount)
        animation.autoreverses = true
        animation.fromValue = 0
        animation.toValue = .pi * 0.1
        layer.add(animation, forKey: "wobble")
    }
    
    func stopWobble() {
        layer.removeAnimation(forKey: "wobble")
    }
    
    func moveTo(_ view: UIView, duration: CFTimeInterval = 0.5, completion: (() -> Void)? = nil) {
        UIView.animate(withDuration: duration, animations: {
            self.frame.origin = CGPoint(x: view.center.x - self.frame.width / 2,
                                        y: view.center.y - self.frame.height / 2)
            
        }) { _ in
            completion?()
        }
    }
    
    func moveTo(_ position: CGPoint, duration: CFTimeInterval = 0.5, completion: (() -> Void)? = nil) {
        UIView.animate(withDuration: duration, animations: {
            self.frame.origin = position
            
        }) { _ in
            completion?()
        }
    }
    
    func slideRightOut(duration: CFTimeInterval = 0.5, completion: (() -> Void)? = nil) {
        guard let theSuperview = superview else {
            return
        }
        
        UIView.animate(withDuration: duration, animations: {
            self.frame.origin.x = theSuperview.bounds.width
            
        }) { _ in
            completion?()
        }
    }
    
    func fadeIn(duration: CFTimeInterval = 0.2, completion: (() -> Void)? = nil) {
        alpha = 0
        UIView.animate(withDuration: duration, animations: {
            self.alpha = 1
            
        }) { _ in
            completion?()
        }
    }
    
    func fadeOut(duration: CFTimeInterval = 0.2, completion: (() -> Void)? = nil) {
        alpha = 1
        UIView.animate(withDuration: duration, animations: {
            self.alpha = 0
            
        }) { _ in
            completion?()
        }
    }
    
    func rotate(duration: CFTimeInterval = 1, repeatCount: CGFloat = .infinity) {
        let animation = CABasicAnimation(keyPath: "transform.rotation")
        animation.duration = duration
        animation.repeatCount = Float(repeatCount)
        animation.fromValue = 0
        animation.toValue = Float.pi * 2
        layer.add(animation, forKey: "rotate")
    }
    
    func stopRotate() {
        layer.removeAnimation(forKey: "rotate")
    }
}
