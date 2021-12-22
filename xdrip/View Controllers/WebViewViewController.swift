//
//  WebViewViewController.swift
//  xdrip
//
//  Created by Yuanbin Cai on 2021/12/22.
//  Copyright © 2021 Johan Degraeve. All rights reserved.
//

import UIKit
import WebKit

class WebViewViewController: UIViewController, WKNavigationDelegate {
    
    private let url: URL
    private let theTitle: String?
    
    private let webView = WKWebView()
    
    init(url: URL, title: String? = nil) {
        self.url = url
        self.theTitle = title
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if let theTitle = theTitle {
            title = theTitle
        }
        
        setupView()
        
        webView.load(URLRequest(url: url))
    }
    
    private func setupView() {
        view.backgroundColor = ConstantsUI.mainBackgroundColor
        
        webView.navigationDelegate = self
        webView.allowsBackForwardNavigationGestures = true
        view.addSubview(webView)
        webView.snp.makeConstraints { (make) in
            make.size.equalTo(view.safeAreaLayoutGuide)
            make.center.equalTo(view.safeAreaLayoutGuide)
        }
    }
}
