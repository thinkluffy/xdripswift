//
//  RemoteConfigHost.swift
//  xdrip
//
//  Created by Yuanbin Cai on 2021/12/30.
//  Copyright © 2021 zDrip. All rights reserved.
//

import SwiftyJSON

class RemoteConfigHost {
    
    private static func commonKey(key: String) -> String {
        return "com_\(key)"
    }
    
    private static func appKey(key: String) -> String {
        return "app_\(key)"
    }
    
    // MARK: - common keys
    
    static var testMode: Bool {
        get {
            UserDefaults.standard.isRemoteConfigTestMode
        }
        set {
            RemoteConfig.shared.testMode = newValue
            UserDefaults.standard.isRemoteConfigTestMode = newValue
        }
    }
    
    static var latestAppVersion: JSON {
        RemoteConfig.shared.value(forKey: commonKey(key: "LatestAppVersion"), defaultValue: JSON())
    }
    
    // MARK: - app keys
    
    static var fullFeatureMode: Bool {
        RemoteConfig.shared.value(forKey: appKey(key: "FullFeatureMode"), defaultValue: true)
    }
}
