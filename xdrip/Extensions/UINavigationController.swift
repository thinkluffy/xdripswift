//
//  UINavigationController.swift
//  xdrip
//
//  Created by Liu Xudong on 2022/1/7.
//  Copyright © 2022 zDrip. All rights reserved.
//

import Foundation
import UIKit

extension UINavigationController {
	func setNoBackground() {
		self.navigationBar.setBackgroundImage(UIImage(), for: .default)
		self.navigationBar.setBackgroundImage(UIImage(), for: .compact)
		self.navigationBar.shadowImage = UIImage()
	}
}
