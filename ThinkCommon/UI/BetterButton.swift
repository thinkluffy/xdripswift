//
//  BetterButton.swift
//  Paintist
//
//  Created by Yuanbin Cai on 2020/5/24.
//  Copyright © 2020 thinkyeah. All rights reserved.
//

import UIKit

@IBDesignable
public class BetterButton: UIControl {

    @IBInspectable
    public var cornerRadius: CGFloat = 0.0 {
        didSet {
            setupCornors()
        }
    }
    
    @IBInspectable
    public var fullyRoundedCorners: Bool = false {
        didSet {
            setupCornors()
        }
    }
    
    private var _bgColor: UIColor = .clear
    @IBInspectable
    public var bgColor: UIColor {
        get {
            return _bgColor
        }
        set {
            _bgColor = newValue
            if !isDisabled {
                contentView.backgroundColor = _bgColor
            }
        }
    }
    
    @IBInspectable
    public var borderColor: UIColor = .clear {
        didSet {
            contentView.layer.borderColor = borderColor.cgColor
        }
    }
    
    @IBInspectable
    public var borderWidth: CGFloat = 0.0 {
        didSet {
            contentView.layer.borderWidth = borderWidth
        }
    }
    
    @IBInspectable
    public var titleText: String = "" {
        didSet {
            titleLabel.text = titleText
            invalidateIntrinsicContentSize()
        }
    }
    
    @IBInspectable
    public var titleColor: UIColor = .white {
        didSet {
            if !isDisabled {
                titleLabel.textColor = titleColor
            }
        }
    }
    
    @IBInspectable
    public var titleColorWhenDisabled: UIColor = .darkText {
        didSet {
            if isDisabled {
                titleLabel.textColor = titleColor
            }
        }
    }
    
    @IBInspectable
    public var titleFont: UIFont = .systemFont(ofSize: 14) {
        didSet {
            titleLabel.font = titleFont
            invalidateIntrinsicContentSize()
        }
    }
    
    @IBInspectable
    public var iconImage: UIImage? {
        didSet {
            iconImageView.image = iconImage
            if iconImage != nil {
                iconImageView.snp.updateConstraints { (make) in
                    make.size.equalTo(iconSize)
                    make.trailing.equalTo(titleLabel.snp.leading).offset(-iconTitleGap)
                }
                
            } else {
                iconImageView.snp.updateConstraints { (make) in
                    make.size.equalTo(0)
                    make.trailing.equalTo(titleLabel.snp.leading).offset(0)
                }
            }
            invalidateIntrinsicContentSize()
        }
    }
    
    @IBInspectable
    public var iconSize: CGFloat = 20 {
        didSet {
            if iconImage != nil {
                iconImageView.snp.updateConstraints { (make) in
                    make.size.equalTo(iconSize)
                }
            }
            invalidateIntrinsicContentSize()
        }
    }

    @IBInspectable
    public var iconTitleGap: CGFloat = 5 {
        didSet {
            guard iconImage != nil else {
                return
            }
            
            iconImageView.snp.updateConstraints { (make) in
                make.trailing.equalTo(titleLabel.snp.leading).offset(-iconTitleGap)
            }
            invalidateIntrinsicContentSize()
        }
    }
    
    @IBInspectable
    public var isDisabled: Bool = false {
        didSet {
            if isDisabled {
                contentView.backgroundColor = .rgba(224, 224, 224)
                titleLabel.textColor = titleColorWhenDisabled
                isUserInteractionEnabled = false
                
            } else {
                contentView.backgroundColor = _bgColor
                titleLabel.textColor = titleColor
                isUserInteractionEnabled = true
            }
        }
    }
    
    private let contentView: UIView = {
        let view = UIView()
        view.clipsToBounds = true
        view.isUserInteractionEnabled = false
        return view
    }()
    
    private lazy var iconImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.frame = .zero
        imageView.contentMode = .scaleAspectFit
        return imageView
    }()
    
    private lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.textColor = .white
        label.font = .systemFont(ofSize: 14)
        return label
    }()
        
    private lazy var centerArea: UIView = {
        let view = UIView()
        view.isUserInteractionEnabled = false
        return view
    }()

    private lazy var shimmer: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.white.withAlphaComponent(0.5)
        view.isUserInteractionEnabled = false
        return view
    }()
    
    private let minWidth: CGFloat = 50
    private let minHeight: CGFloat = 30
    private let paddingHorizontal: CGFloat = 20
    private let paddingVertical: CGFloat = 10
    
    private var isPlayingShimmer = false
    private var playingShimmerTimer: Timer?
    
    init() {
        super.init(frame: .zero)
        setup()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }
    
    private func setup() {
        centerArea.addSubview(iconImageView)
        centerArea.addSubview(titleLabel)
        contentView.addSubview(centerArea)
        addSubview(contentView)
        
        centerArea.snp.makeConstraints { (make) in
            make.leading.equalTo(iconImageView)
            make.trailing.equalTo(titleLabel)
            make.top.equalTo(titleLabel)
            make.bottom.equalTo(titleLabel)
            make.center.equalToSuperview()
        }
        
        titleLabel.snp.makeConstraints { (make) in
            make.centerY.equalTo(centerArea)
        }
        
        iconImageView.snp.makeConstraints { (make) in
            make.centerY.equalTo(titleLabel)
            make.trailing.equalTo(titleLabel.snp.leading)
            make.size.equalTo(0)
        }
        
        contentView.snp.makeConstraints { (make) in
            make.leading.top.trailing.bottom.equalTo(self)
        }
    }
    
    public override var intrinsicContentSize: CGSize {
        var width = titleLabel.intrinsicContentSize.width + paddingHorizontal * 2
        if iconImage != nil {
            width += iconSize + iconTitleGap
        }
        width = max(width, minWidth)
        
        var height = titleLabel.intrinsicContentSize.height
        if iconImage != nil {
            height = max(height, iconSize)
        }
        height = max(height + paddingVertical * 2, minHeight)
        
        return CGSize(width: width, height: height)
    }
    
    private func setupCornors() {
        if fullyRoundedCorners {
            contentView.layer.cornerRadius = contentView.layer.bounds.height / 2
            
        } else {
            contentView.layer.cornerRadius = cornerRadius
        }
    }
    
    public override func layoutSubviews() {
        super.layoutSubviews()
        setupCornors()
        if isPlayingShimmer {
            shimmer.frame.size.height = bounds.height
        }
    }
    
    public override func removeFromSuperview() {
        playingShimmerTimer?.invalidate()
        playingShimmerTimer = nil
        super.removeFromSuperview()
    }
    
    public override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesBegan(touches, with: event)
        alpha = 0.7
    }
    
    public override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        alpha = 1
        super.touchesCancelled(touches, with: event)
    }
    
    public override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        alpha = 1
        super.touchesEnded(touches, with: event)
    }
    
    public func playShimmer() {
        guard !isPlayingShimmer else {
            return
        }
        isPlayingShimmer = true
        
        contentView.addSubview(shimmer)
        shimmer.frame = CGRect(x: -20, y: 0, width: 20, height: bounds.height)
        playingShimmerTimer = Timer.scheduledTimer(withTimeInterval: 2.5, repeats: true) { timer in
            self.shimmer.frame.origin.x = -20
            UIView.animate(withDuration: 0.8) {
                self.shimmer.frame.origin.x = self.bounds.width
            }
        }
    }
    
    public func stopPlayShimmer() {
        guard isPlayingShimmer else {
            return
        }
        playingShimmerTimer?.invalidate()
        playingShimmerTimer = nil
        shimmer.removeFromSuperview()
    }
    
    public override func prepareForInterfaceBuilder() {
        setup()
        titleText = "Better Button"
    }
}
