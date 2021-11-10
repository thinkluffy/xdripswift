//
//  iOS.swift
//  Paintist
//
//  Created by Yuanbin Cai on 2020/5/21.
//  Copyright © 2020 thinkyeah. All rights reserved.
//

import UIKit
import AdSupport
import AppTrackingTransparency

public class iOS {
    
    private init() {}
    
    public static var appDisplayName: String {
        return Bundle.main.object(forInfoDictionaryKey: "CFBundleDisplayName") as! String
    }
    
    public static var appVersionCode: Int {
        if let version = Bundle.main.infoDictionary?["CFBundleVersion"] as? String {
            if let versionCode = Int(version) {
                return versionCode
            }
        }
        return 0
    }
    
    public static var appVersionName: String {
        return Bundle.main.infoDictionary?["CFBundleShortVersionString"] as! String
    }
    
    public static var systemVersion: String {
        UIDevice.current.systemVersion
    }
    
    public static var platform: String {
        var size = 0
        sysctlbyname("hw.machine", nil, &size, nil, 0)
        var machine = [CChar](repeating: 0,  count: size)
        sysctlbyname("hw.machine", &machine, &size, nil, 0)
        return String(cString: machine)
    }
    
    public static var appBuildDate: Date {
        if let infoPath = Bundle.main.path(forResource: "Info", ofType: "plist"),
            let infoAttr = try? FileManager.default.attributesOfItem(atPath: infoPath),
            let infoDate = infoAttr[.modificationDate] as? Date {
            return infoDate
        }
        return Date()
    }
    
    public static func language(withRegion: Bool = true) -> String {
        let identifier = Locale.current.identifier // maybe en, en_US, zh-Hans_US
        if identifier.lowercased().starts(with: "zh-hant") {
            return "zh_TW"
        }
        
        if identifier.lowercased().starts(with: "zh-hans") {
            return "zh_CN"
        }
        
        let parts = identifier.split(separator: "_")
        guard parts.count >= 1 else {
            return "en"
        }

        var lang = String(parts[0])
        var region: String? = nil
        if parts.count >= 2 {
            region = String(parts[1])
        }
        
        let langParts = lang.split(separator: "-")
        guard langParts.count >= 1 else {
            return "en"
        }
        
        if langParts.count > 1 {
            lang = String(langParts[0])
        }
        
        if withRegion && region != nil {
            return "\(lang)_\(region!)"
        }
        return lang
    }
    
    public static var region: String? {
        NSLocale.current.regionCode
    }
    
    public static var idfa: String? {
        // check if advertising tracking is enabled in user’s setting
		if #available(iOS 14, *) {
			if .authorized == ATTrackingManager.trackingAuthorizationStatus {
				return ASIdentifierManager.shared().advertisingIdentifier.uuidString
			}
		}
		else if ASIdentifierManager.shared().isAdvertisingTrackingEnabled {
			return ASIdentifierManager.shared().advertisingIdentifier.uuidString
		}
		return nil
    }
    
    public static var isPhone: Bool {
        UIDevice.current.userInterfaceIdiom == .phone
    }
    
    public static var isPad: Bool {
        UIDevice.current.userInterfaceIdiom == .pad
    }
    
    public static var safeAreaTop: CGFloat = {
        return UIApplication.shared.keyWindow?.safeAreaInsets.top ?? 0
    }()
    
    public static var safeAreaBottom: CGFloat = {
        return UIApplication.shared.keyWindow?.safeAreaInsets.bottom ?? 0
    }()
    
    public static func openAppSettings() -> Bool {
        if let bundleIdentifier = Bundle.main.bundleIdentifier,
            let appSettings = URL(string: UIApplication.openSettingsURLString + bundleIdentifier) {
            if UIApplication.shared.canOpenURL(appSettings) {
                UIApplication.shared.open(appSettings)
                return true
            }
        }
        return false
    }
}
