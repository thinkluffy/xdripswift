//
//  TabLayout.swift
//  Paintist
//
//  Created by Yuanbin Cai on 2020/4/16.
//  Copyright © 2020 thinkyeah. All rights reserved.
//

import UIKit

public enum TabLayoutIndicatorType {
    case underline
    case aroundButton
}

public struct TabLayoutConfig {
    
    public static let shared = TabLayoutConfig()
    
    public var type: TabLayoutType
    public var horizontalMargin: CGFloat
    public var horizontalSpace: CGFloat
    public var normalTitleFont: UIFont
    public var selectedTitleFont: UIFont
    public var normalTitleColor: UIColor
    public var selectedTitleColor: UIColor
    public var indicatorType: TabLayoutIndicatorType
    /// Only work for .underline indicatorType. In .aroundButton type, indicator width will automatically wrap the button
    public var indicatorWidth: CGFloat
    public var indicatorHeight: CGFloat
    public var indicatorColor: UIColor
    public var indicatorPanelColor: UIColor
    public var backgroundColor: UIColor = .white
    
    public init(type: TabLayoutType = .segement,
                horizontalMargin: CGFloat = 16,
                horizontalSpace: CGFloat = 32,
                normalTitleFont: UIFont = .systemFont(ofSize: 15),
                selectedTitleFont: UIFont = .systemFont(ofSize: 15, weight: .medium),
                normalTitleColor: UIColor = .gray,
                selectedTitleColor: UIColor = .darkGray,
                indicatorType: TabLayoutIndicatorType = .underline,
                indicatorWidth: CGFloat = 30,
                indicatorHeight: CGFloat = 2,
                indicatorColor: UIColor = .darkGray,
                indicatorPanelColor: UIColor = .clear,
                backgroundColor: UIColor = .white) {
        self.type = type
        self.horizontalMargin = horizontalMargin
        self.horizontalSpace = horizontalSpace
        self.normalTitleFont = normalTitleFont
        self.selectedTitleFont = selectedTitleFont
        self.normalTitleColor = normalTitleColor
        self.selectedTitleColor = selectedTitleColor
        self.indicatorType = indicatorType
        self.indicatorWidth = indicatorWidth
        self.indicatorHeight = indicatorHeight
        self.indicatorColor = indicatorColor
        self.indicatorPanelColor = indicatorPanelColor
        self.backgroundColor = backgroundColor
    }
}

public enum TabLayoutType {
    case tab
    case segement
}

public protocol TabLayoutDelegate: AnyObject {
        
    var titlesInTabLayout: [String] { get }

    func tabLayout(_ tabLayout: TabLayout, didSelectAtIndex index: Int, animated: Bool)
    
}

public class TabLayout: UIView {
    
    private let scrollView = UIScrollView()
    private let indicatorView = UIView()
    private let indicatorsPanel = UIView()
    private var titleButtons: [UIButton] = []
    private var initSelectedIndex: Int?
    private var innerConfig: TabLayoutConfig = TabLayoutConfig.shared
    
    internal var gestureRecognizersInScrollView: [UIGestureRecognizer]? {
        return scrollView.gestureRecognizers
    }
    
    public private(set) var selectedIndex: Int?
    public weak var delegate: TabLayoutDelegate?
    
    /// you must call `reloadData()` to make it work, after the assignment.
    public var config: TabLayoutConfig = TabLayoutConfig.shared
    
    public override var intrinsicContentSize: CGSize {
        return scrollView.contentSize
    }
    
    public override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }
    
    public required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setup()
    }
    
    private func setup() {
        addSubview(scrollView)
        if #available(iOS 11.0, *) {
            scrollView.contentInsetAdjustmentBehavior = .never
        }
        scrollView.snp.makeConstraints({ (make) in
            make.size.equalTo(self)
            make.center.equalTo(self)
        })
        scrollView.showsHorizontalScrollIndicator = false
        scrollView.showsVerticalScrollIndicator = false
        scrollView.backgroundColor = .clear
    }
    
    public override func layoutSubviews() {
        super.layoutSubviews()
        layoutTitleButtons()
        recoverInitSelectedIndex()
        updateSelectedIndex()
    }
    
    /// relayout subViews
    ///
    /// you should call `selectSwitcher(at index: Int, animated: Bool)` after call the method.
    /// otherwise, none of them will be selected.
    /// However, if an item was previously selected, it will be reSelected.
    public func reloadData() {
        for titleButton in titleButtons {
            titleButton.removeFromSuperview()
            titleButton.frame = .zero
        }
        titleButtons.removeAll()
        indicatorView.removeFromSuperview()
        indicatorView.frame = .zero
        scrollView.isScrollEnabled = innerConfig.type == .segement
        innerConfig = config
        guard let titles = delegate?.titlesInTabLayout else { return }
        guard !titles.isEmpty else { return }
        for (index, title) in titles.enumerated() {
            let button = UIButton(type: .custom)
            button.clipsToBounds = false
            button.titleLabel?.font = innerConfig.normalTitleFont
            button.backgroundColor = .clear
            button.setTitle(title, for: .normal)
            button.tag = index
            button.setTitleColor(innerConfig.normalTitleColor, for: .normal)
            button.addTarget(self, action: #selector(didClickTitleButton), for: .touchUpInside)
            scrollView.addSubview(button)
            titleButtons.append(button)
        }
        guard !titleButtons.isEmpty else { return }
        
        scrollView.addSubview(indicatorView)
        scrollView.sendSubviewToBack(indicatorView)
        indicatorView.layer.masksToBounds = true
        indicatorView.layer.cornerRadius = innerConfig.indicatorHeight/2
        indicatorView.backgroundColor = innerConfig.indicatorColor
        
        scrollView.addSubview(indicatorsPanel)
        scrollView.sendSubviewToBack(indicatorsPanel)
        indicatorsPanel.layer.masksToBounds = true
        indicatorsPanel.layer.cornerRadius = innerConfig.indicatorHeight/2
        indicatorsPanel.backgroundColor = innerConfig.indicatorPanelColor
        
        backgroundColor = innerConfig.backgroundColor
        layoutTitleButtons()
        updateSelectedIndex()
    }
    
    /// select one tab by index
    public func selectTab(at index: Int, animated: Bool, triggerDelegate: Bool = true) {
        updateSelectedButton(at: index, animated: animated, triggerDelegate: triggerDelegate)
    }
    
}

extension TabLayout {
    
    private func recoverInitSelectedIndex() {
        guard let initSelectedIndex = initSelectedIndex else { return }
        self.initSelectedIndex = nil
        updateSelectedButton(at: initSelectedIndex, animated: false)
    }
    
    private func updateSelectedIndex() {
        guard let selectedIndex = selectedIndex else { return }
        updateSelectedButton(at: selectedIndex, animated: false)
    }
    
    private func layoutTitleButtons() {
        guard scrollView.frame != .zero else { return }
        guard !titleButtons.isEmpty else {
            scrollView.contentSize = CGSize(width: bounds.width, height: bounds.height)
            return
        }
        var offsetX = innerConfig.horizontalMargin
        for titleButton in titleButtons {
            let buttonWidth: CGFloat
            switch innerConfig.type {
            case .tab:
                buttonWidth = (bounds.width-innerConfig.horizontalMargin*2)/CGFloat(titleButtons.count)
            case .segement:
                let title = titleButton.title(for: .normal) ?? ""
                let normalButtonWidth = title.boundingWidth(with: innerConfig.normalTitleFont)
                let selectedButtonWidth = title.boundingWidth(with: innerConfig.selectedTitleFont)
                buttonWidth = selectedButtonWidth > normalButtonWidth ? selectedButtonWidth : normalButtonWidth
            }
            titleButton.frame = CGRect(x: offsetX, y: 0, width: buttonWidth, height: scrollView.bounds.height)
            switch innerConfig.type {
            case .tab:
                offsetX += buttonWidth
            case .segement:
                offsetX += buttonWidth + innerConfig.horizontalSpace
            }
        }
        switch innerConfig.type {
        case .tab:
            scrollView.contentSize = CGSize(width: bounds.width, height: bounds.height)
        case .segement:
            scrollView.contentSize = CGSize(width: offsetX - innerConfig.horizontalSpace + innerConfig.horizontalMargin, height: bounds.height)
        }
        
        if !titleButtons.isEmpty {
            let firstButton = titleButtons.first!
            let lastButton = titleButtons.last!
            
            let titleBtnBgFrame = CGRect(x: firstButton.frame.origin.x - 15,
                                         y: (frame.height - innerConfig.indicatorHeight) / 2,
                                         width: lastButton.frame.origin.x + lastButton.bounds.size.width - firstButton.frame.origin.x + 30,
                                         height: innerConfig.indicatorHeight)
            indicatorsPanel.frame = titleBtnBgFrame
        }
    }
    
    private func updateSelectedButton(at index: Int, animated: Bool, triggerDelegate: Bool = true) {
        guard scrollView.frame != .zero else {
            initSelectedIndex = index
            return
        }
        guard titleButtons.count != 0 else { return }
        if let selectedIndex = selectedIndex, selectedIndex >= 0, selectedIndex < titleButtons.count {
            let titleButton = titleButtons[selectedIndex]
            titleButton.setTitleColor(innerConfig.normalTitleColor, for: .normal)
            titleButton.titleLabel?.font = innerConfig.normalTitleFont
        }
        guard index >= 0, index < titleButtons.count else { return }
        let titleButton = titleButtons[index]
        titleButton.setTitleColor(innerConfig.selectedTitleColor, for: .normal)
        titleButton.titleLabel?.font = innerConfig.selectedTitleFont
        
        let indicatorFrame: CGRect
        if innerConfig.indicatorType == .underline {
            indicatorFrame = CGRect(x: titleButton.frame.origin.x + (titleButton.bounds.width - innerConfig.indicatorWidth)/2,
                                    y: frame.height - innerConfig.indicatorHeight,
                                    width: innerConfig.indicatorWidth,
                                    height: innerConfig.indicatorHeight)
            
        } else if innerConfig.indicatorType == .aroundButton {
            indicatorFrame = CGRect(x: titleButton.frame.origin.x - 15,
                                    y: (frame.height - innerConfig.indicatorHeight) / 2,
                                    width: titleButton.bounds.size.width + 30,
                                    height: innerConfig.indicatorHeight)
            
        } else {
            fatalError("Unexpected indicatorType: \(innerConfig.indicatorType)")
        }
        
        if animated, indicatorView.frame != .zero {
            UIView.animate(withDuration: 0.25) {
                self.indicatorView.frame = indicatorFrame
            }
            
        } else {
            indicatorView.frame = indicatorFrame
        }
        
        if case .segement = innerConfig.type {
            var offsetX = titleButton.frame.origin.x-(scrollView.bounds.width-titleButton.bounds.width)/2
            if offsetX < 0 {
                offsetX = 0
            } else if (offsetX+scrollView.bounds.width) > scrollView.contentSize.width {
                offsetX = scrollView.contentSize.width-scrollView.bounds.width
            }
            if scrollView.contentSize.width > scrollView.bounds.width {
                scrollView.setContentOffset(CGPoint(x: offsetX, y: scrollView.contentOffset.y), animated: animated)
            }
        }
        guard index != selectedIndex else { return }
        selectedIndex = index
        if triggerDelegate {
            delegate?.tabLayout(self, didSelectAtIndex: index, animated: animated)
        }
    }
    
    @objc private func didClickTitleButton(_ button: UIButton) {
        selectTab(at: button.tag, animated: true)
    }
}

