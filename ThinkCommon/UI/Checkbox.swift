//
//  Checkbox.swift
//  xdrip
//
//  Created by Yuanbin Cai on 2021/12/22.
//  Copyright © 2021 Johan Degraeve. All rights reserved.
//

import UIKit

@IBDesignable open class Checkbox: UIButton {

    /*
    * Variable describes UICheckbox padding
    */
    @IBInspectable open var padding: CGFloat = CGFloat(15)

   /*
   * Variable describes UICheckbox border width
   */
    @IBInspectable open var borderWidth: CGFloat = 2.0 {
        didSet {
            layer.borderWidth = borderWidth
        }
    }

    /*
    * Variable stores UICheckbox border color
    */
    @IBInspectable open var borderColor: UIColor = UIColor.lightGray {
        didSet {
            layer.borderColor = borderColor.cgColor
        }
    }

    /*
    * Variable stores UICheckbox border radius
    */
    @IBInspectable open var cornerRadius: CGFloat = 5.0 {
        didSet {
            layer.cornerRadius = cornerRadius
        }
    }

    /*
    * Variable to store current UICheckbox select status
    */
    override open var isSelected: Bool {
        didSet {
            super.isSelected = isSelected
            onSelectStateChangedCallback?(self, isSelected)
        }
    }

    /*
    * Callback for handling checkbox status change
    */
    private var onSelectStateChangedCallback: ((_ checkbox: Checkbox, _ selected: Bool) -> Void)?

    open func onSelectStateChagned(_ onChagned: @escaping ((_ checkbox: Checkbox, _ selected: Bool) -> Void)) {
        onSelectStateChangedCallback = onChagned
    }
    
    // MARK: Init
    /*
    * Create a new instance of a UICheckbox
    */
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        initDefaultParams()
    }

    /*
    * Create a new instance of a UICheckbox
    */
    override init(frame: CGRect) {
        super.init(frame: frame)
        initDefaultParams()
    }
    
    /*
     * Increase UICheckbox 'clickability' area for better UX
     */
    override open func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
        
        let newBound = CGRect(
            x: self.bounds.origin.x - padding,
            y: self.bounds.origin.y - padding,
            width: self.bounds.width + 2 * padding,
            height: self.bounds.width + 2 * padding
        )
        
        return newBound.contains(point)
    }
    
    override open func prepareForInterfaceBuilder() {
        setTitle("", for: UIControl.State())
    }
    
}

// MARK: Private methods
public extension Checkbox {

    fileprivate func initDefaultParams() {
        addTarget(self, action: #selector(Checkbox.checkboxTapped), for: .touchUpInside)
        setTitle(nil, for: UIControl.State())

        clipsToBounds = true

        setCheckboxImage()
    }
    
    fileprivate func setCheckboxImage() {
//        let frameworkBundle = Bundle(for: Checkbox.self)
//        let bundleURL = frameworkBundle.resourceURL?.appendingPathComponent("UICheckbox.bundle")
//        let resourceBundle = Bundle(url: bundleURL!)
        let image = R.image.ic_check()
        imageView?.contentMode = .scaleAspectFit

        setImage(nil, for: UIControl.State())
        setImage(image, for: .selected)
        setImage(image, for: .highlighted)
    }

    @objc fileprivate func checkboxTapped(_ sender: Checkbox) {
        isSelected = !isSelected
    }
}
