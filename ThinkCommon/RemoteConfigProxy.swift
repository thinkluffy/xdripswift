//
//  RemoteConfigProxy.swift
//  Paintist
//
//  Created by Yuanbin Cai on 2020/5/3.
//  Copyright © 2020 thinkyeah. All rights reserved.
//

import Firebase
import SwiftyJSON

public class RemoteConfigProxy {
    
    private static let log = Log(type: RemoteConfigProxy.self)
    
    public static let shared = RemoteConfigProxy()
    
    private let remoteConfig = RemoteConfig.remoteConfig()
    
    private init() {}
    
    public func setup() {
        let settings = RemoteConfigSettings()
        settings.minimumFetchInterval = 0
        remoteConfig.configSettings = settings
    }
    
    public var versionId: Int {
        configValue(forKey: "com_VersionId", defaultValue: 0)
    }
    
    public var testMode: Bool = false
    
    public func refresh(completion: ((_ refreshed: Bool) -> Void)? = nil) {
        remoteConfig.fetch(withExpirationDuration: TimeInterval(0)) { (status, error) -> Void in
            if status == .success {
                RemoteConfigProxy.log.i("Config fetched!")
                self.remoteConfig.activate { (_, error) in
                    RemoteConfigProxy.log.i("VersionId: \(self.versionId)")
                    DispatchQueue.main.async {
                        completion?(true)
                    }
                }
                
            } else {
                RemoteConfigProxy.log.e("Config not fetched, error: \(error?.localizedDescription ?? "No error available.")")
                DispatchQueue.main.async {
                    completion?(false)
                }
            }
        }
    }
    
    public func configValue(forKey key: String, defaultValue: String) -> String {
		if testMode {
			let value = remoteConfig.configValue(forKey: "test_" + key)
			if let stringValue = value.stringValue, stringValue.count > 0 {
				return stringValue
			}
		}
        let value = remoteConfig.configValue(forKey: key)
        guard let stringValue = value.stringValue, stringValue.count > 0 else {
            return defaultValue
        }
        return stringValue
    }
    
    public func configValue(forKey key: String, defaultValue: Int) -> Int {
		if testMode {
			let value = remoteConfig.configValue(forKey: "test_" + key)
			if let stringValue = value.stringValue, stringValue.count > 0, let intValue = Int(stringValue) {
				return intValue
			}
		}
		let value = remoteConfig.configValue(forKey: key)
        guard let stringValue = value.stringValue, stringValue.count > 0, let intValue = Int(stringValue) else {
            return defaultValue
        }
        return intValue
    }
    
    public func configValue(forKey key: String, defaultValue: Bool) -> Bool {
		if testMode {
			let value = remoteConfig.configValue(forKey: "test_" + key)
			if value.dataValue.count > 0 {
				return value.boolValue
			}
		}
        let value = remoteConfig.configValue(forKey: key)
        guard value.dataValue.count > 0 else {
            return defaultValue
        }
        return value.boolValue
    }
    
    public func configValue(forKey key: String, defaultValue: JSON) -> JSON {
		if testMode {
			let value = remoteConfig.configValue(forKey: "test_\(key)")
			if value.dataValue.count > 0,
				let jsonValue = try? JSON(data: value.dataValue) {
				return jsonValue
			}
		}
        let value = remoteConfig.configValue(forKey: key)
        guard value.dataValue.count > 0,
            let jsonValue = try? JSON(data: value.dataValue) else {
            return defaultValue
        }
        return jsonValue
    }
}
