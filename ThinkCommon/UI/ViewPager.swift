//
//  ViewPager.swift
//  Paintist
//
//  Created by Yuanbin Cai on 2020/4/16.
//  Copyright © 2020 thinkyeah. All rights reserved.
//

import UIKit

@objc public protocol ViewPagerDelegate: AnyObject {
    
    func viewPager(_ viewPager: ViewPager, didMoveTo index: Int)
    
    var viewControllers: [UIViewController] { get }
    
}

@IBDesignable public class ViewPager: UIView {

    public weak var hostingViewController: UIViewController! {
        didSet {
            hostingViewController.addChild(pageViewController)
        }
    }
    
    @IBOutlet public weak var delegate: ViewPagerDelegate?
    
    public var currentIndex: Int {
        guard let firstVC = pageViewController.viewControllers?.first else {
            return 0
        }
        return viewControllers.firstIndex(of: firstVC) ?? 0
    }
    
    public var isInfinite = false
    
    private var pageViewController: UIPageViewController!
    private var viewControllers: [UIViewController] = []
    
    public override init(frame: CGRect) {
        super.init(frame: frame)
        otherInit()
    }
    
    public required init?(coder: NSCoder) {
        super.init(coder: coder)
        otherInit()
    }
    
    private func otherInit() {
        pageViewController = UIPageViewController(transitionStyle: .scroll, navigationOrientation: .horizontal, options: nil)
        pageViewController.dataSource = self
        pageViewController.delegate = self
        
        addSubview(pageViewController.view)
        pageViewController.view.snp.makeConstraints { (make) in
            make.size.equalTo(self)
            make.center.equalTo(self)
        }
    }
    
    public func reloadData() {
        if let controllers = delegate?.viewControllers {
            viewControllers = controllers
            if let first = viewControllers.first {
                pageViewController.setViewControllers([first], direction: .forward,
                                                      animated: false, completion: nil)
            }
        }
    }
    
    public func selectPage(at index: Int, animated: Bool, triggerDelegate: Bool = true) {
        guard currentIndex != index, index < viewControllers.count, index >= 0 else {
            return
        }
        
        let direction: UIPageViewController.NavigationDirection = index < currentIndex ? .reverse : .forward
        
        pageViewController.setViewControllers([viewControllers[index]], direction: direction, animated: animated, completion: nil)
        if triggerDelegate {
            self.delegate?.viewPager(self, didMoveTo: viewControllers.firstIndex(of: pageViewController.viewControllers!.first!)!)
        }
    }
}

extension ViewPager: UIPageViewControllerDataSource {
    
    public func pageViewController(_ pageViewController: UIPageViewController, viewControllerBefore viewController: UIViewController) -> UIViewController? {
        guard let viewControllerIndex = viewControllers.firstIndex(of: viewController) else {
            return nil
        }
         
        let previousIndex = viewControllerIndex - 1
        if !isInfinite {
            guard previousIndex >= 0 else {
                return nil
            }
            return viewControllers[previousIndex]
            
        } else {
            return viewControllers[(previousIndex + viewControllers.count) % viewControllers.count]
        }
    }
    
     public func pageViewController(_ pageViewController: UIPageViewController, viewControllerAfter viewController: UIViewController) -> UIViewController? {
        guard let viewControllerIndex = viewControllers.firstIndex(of: viewController) else {
            return nil
        }
         
        let nextIndex = viewControllerIndex + 1
        if !isInfinite {
            guard nextIndex < viewControllers.count else {
                return nil
            }
            return viewControllers[nextIndex]
            
        } else {
            return viewControllers[nextIndex % viewControllers.count]
        }
    }
}

extension ViewPager: UIPageViewControllerDelegate {
    
    public func pageViewController(_ pageViewController: UIPageViewController, willTransitionTo pendingViewControllers: [UIViewController]) {
    }

    public func pageViewController(_ pageViewController: UIPageViewController, didFinishAnimating finished: Bool, previousViewControllers: [UIViewController], transitionCompleted completed: Bool) {
        if completed {
            self.delegate?.viewPager(self, didMoveTo: currentIndex)
        }
    }
}
