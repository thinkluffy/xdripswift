//
//  RemoteConfig.swift
//  Paintist
//
//  Created by Yuanbin Cai on 2020/5/3.
//  Copyright © 2020 thinkyeah. All rights reserved.
//

import SwiftyJSON

public class RemoteConfig {
    
    private static let log = Log(type: RemoteConfig.self)
    
    public static let shared = RemoteConfig()
    
    private var remoteConfigProvider: RemoteConfigProvider!

    private init() {}
    
    public func initialize(remoteConfigProvider: RemoteConfigProvider) {
        self.remoteConfigProvider = remoteConfigProvider
    }
    
    public var versionId: Int {
        remoteConfigProvider.versionId
    }
    
    public var testMode: Bool = false
    
    public func refresh(completion: ((_ refreshed: Bool) -> Void)? = nil) {
        remoteConfigProvider.refresh(completion: completion)
    }
    
    public func value(forKey key: String, defaultValue: String) -> String {
        if testMode, let testValue = remoteConfigProvider.string(forKey: "test_" + key) {
            return testValue
        }

        return remoteConfigProvider.string(forKey: key) ?? defaultValue
    }
    
    public func value(forKey key: String, defaultValue: Int) -> Int {
        if testMode, let testValue = remoteConfigProvider.int(forKey: "test_" + key) {
            return testValue
        }

        return remoteConfigProvider.int(forKey: key) ?? defaultValue
    }
    
    public func value(forKey key: String, defaultValue: Bool) -> Bool {
        if testMode, let testValue = remoteConfigProvider.bool(forKey: "test_" + key) {
            return testValue
        }

        return remoteConfigProvider.bool(forKey: key) ?? defaultValue
    }
    
    public func value(forKey key: String, defaultValue: JSON) -> JSON {
        if testMode, let testValue = remoteConfigProvider.json(forKey: "test_" + key) {
            return testValue
        }

        return remoteConfigProvider.json(forKey: key) ?? defaultValue
    }
}
