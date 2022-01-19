//
//  FirebaseRemoteConfig.swift
//  xdrip
//
//  Created by Yuanbin Cai on 2022/1/19.
//  Copyright © 2022 zDrip. All rights reserved.
//

import Firebase
import SwiftyJSON

public class Frc: RemoteConfigProvider {

    private static let log = Log(type: Frc.self)

    private let remoteConfig = Firebase.RemoteConfig.remoteConfig()

    public init() {
        let settings = RemoteConfigSettings()
        settings.minimumFetchInterval = 0
        remoteConfig.configSettings = settings
    }

    public var versionId: Int {
        int(forKey: "com_VersionId") ?? 0
    }

    public func refresh(completion: ((Bool) -> Void)?) {
        remoteConfig.fetch(withExpirationDuration: TimeInterval(0)) { (status, error) -> Void in
            if status == .success {
                Frc.log.i("Config fetched!")
                self.remoteConfig.activate { (_, error) in
                    Frc.log.i("VersionId: \(self.versionId)")
                    DispatchQueue.main.async {
                        completion?(true)
                    }
                }

            } else {
                Frc.log.e("Config not fetched, error: \(error?.localizedDescription ?? "No error available.")")
                DispatchQueue.main.async {
                    completion?(false)
                }
            }
        }
    }

    public func int(forKey key: String) -> Int? {
        let value = remoteConfig.configValue(forKey: key)
        guard let stringValue = value.stringValue, stringValue.count > 0, let intValue = Int(stringValue) else {
            return nil
        }
        return intValue
    }

    public func bool(forKey key: String) -> Bool? {
        let value = remoteConfig.configValue(forKey: key)
        guard value.dataValue.count > 0 else {
            return nil
        }
        return value.boolValue
    }

    public func string(forKey key: String) -> String? {
        let value = remoteConfig.configValue(forKey: key)
        guard let stringValue = value.stringValue, stringValue.count > 0 else {
            return nil
        }
        return stringValue
    }

    public func json(forKey key: String) -> JSON? {
        let value = remoteConfig.configValue(forKey: key)
        guard value.dataValue.count > 0,
              let jsonValue = try? JSON(data: value.dataValue) else {
            return nil
        }
        return jsonValue
    }
}
