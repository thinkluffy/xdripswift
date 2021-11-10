//
//  ConfigProxy.swift
//  Paintist
//
//  Created by Yuanbin Cai on 2020/4/8.
//  Copyright © 2020 thinkyeah. All rights reserved.
//

import Foundation

public class ConfigProxy {
    
    private let configStore: ConfigStore
    
    init(fileName: String? = nil) {
        if let theFileName = fileName {
            configStore = PlistConfigStore(fileName: theFileName)

        } else {
            configStore = UserDefaultsConfigStore()
        }
    }
    
    public func getValue(key: String, default defaultValue: String) -> String {
        return configStore.string(forKey: key) ?? defaultValue
    }
    
    public func getValue(key: String, default defaultValue: Int) -> Int {
        if configStore.object(forKey: key) == nil {
            return defaultValue
        }
        return configStore.integer(forKey: key)
    }
    
    public func getValue(key: String, default defaultValue: Int64) -> Int64 {
        if configStore.object(forKey: key) == nil {
            return defaultValue
        }
        return Int64(configStore.string(forKey: key)!) ?? defaultValue
    }
    
    public func getValue(key: String, default defaultValue: Float) -> Float {
        if configStore.object(forKey: key) == nil {
            return defaultValue
        }
        return configStore.float(forKey: key)
    }
    
    public func getValue(key: String, default defaultValue: Double) -> Double {
        if configStore.object(forKey: key) == nil {
            return defaultValue
        }
        return configStore.double(forKey: key)
    }
    
    public func getValue(key: String, default defaultValue: Bool) -> Bool {
        if configStore.object(forKey: key) == nil {
            return defaultValue
        }
        return configStore.bool(forKey: key)
    }
    
    public func setValue(key: String, value: String) {
        configStore.set(value, forKey: key)
    }
    
    public func setValue(key: String, value: Int) {
        configStore.set(value, forKey: key)
    }
    
    public func setValue(key: String, value: Int64) {
        configStore.set(String(value), forKey: key)
    }
    
    public func setValue(key: String, value: Float) {
        configStore.set(value, forKey: key)
    }
    
    public func setValue(key: String, value: Double) {
        configStore.set(value, forKey: key)
    }
    
    public func setValue(key: String, value: Bool) {
        configStore.set(value, forKey: key)
    }
}

private protocol ConfigStore {
        
    func object(forKey Key: String) -> Any?
    
    func string(forKey key: String) -> String?
    
    func integer(forKey key: String) -> Int
    
    func int64(forKey key: String) -> Int64
    
    func float(forKey key: String) -> Float
    
    func double(forKey key: String) -> Double
    
    func bool(forKey key: String) -> Bool
    
    func set(_ value: String, forKey key: String)
    
    func set(_ value: Int, forKey key: String)
    
    func set(_ value: Int64, forKey key: String)
    
    func set(_ value: Float, forKey key: String)
    
    func set(_ value: Double, forKey key: String)
    
    func set(_ value: Bool, forKey key: String)
    
}

private class UserDefaultsConfigStore: ConfigStore {
    
    private let preferences = UserDefaults.standard
    
    func object(forKey key: String) -> Any? {
        return preferences.object(forKey: key)
    }
    
    func string(forKey key: String) -> String? {
        return preferences.string(forKey: key)
    }
    
    func integer(forKey key: String) -> Int {
        return preferences.integer(forKey: key)
    }
    
    func int64(forKey key: String) -> Int64 {
        guard let str = preferences.string(forKey: key) else {
            return 0
        }
        return Int64(str) ?? 0
    }
    
    func float(forKey key: String) -> Float {
        return preferences.float(forKey: key)
    }
    
    func double(forKey key: String) -> Double {
        return preferences.double(forKey: key)
    }
    
    func bool(forKey key: String) -> Bool {
        return preferences.bool(forKey: key)
    }
    
    func set(_ value: String, forKey key: String) {
        preferences.set(value, forKey: key)
    }
    
    func set(_ value: Int, forKey key: String) {
        preferences.set(value, forKey: key)
    }
    
    func set(_ value: Int64, forKey key: String) {
        preferences.set(String(value), forKey: key)
    }
    
    func set(_ value: Float, forKey key: String) {
        preferences.set(value, forKey: key)
    }
    
    func set(_ value: Double, forKey key: String) {
        preferences.set(value, forKey: key)
    }
    
    func set(_ value: Bool, forKey key: String) {
        preferences.set(value, forKey: key)
    }
}

private class PlistConfigStore: ConfigStore {
    
    private let fileUrl: URL
    
    private var dict: [String: Any]
    
    private let readWriteLock: ReadWriteLock = PThreadReadWriteLock()
    private let serialQueue: DispatchQueue

    init(fileName: String) {
        fileUrl = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
            .appendingPathComponent(fileName).appendingPathExtension("plist")
        if FileManager.default.fileExists(atPath: fileUrl.path),
            let theDict = NSDictionary(contentsOf: fileUrl) as? [String: Any] {
            dict = theDict
            
        } else {
            dict = [String: Any]()
        }
        serialQueue = DispatchQueue(label: "com.configstore.serialQueue.\(fileName)")
    }
    
    func object(forKey key: String) -> Any? {
        readWriteLock.withReadLock { () -> Any? in
            return dict[key]
        }
    }
    
    func string(forKey key: String) -> String? {
        readWriteLock.withReadLock { () -> String? in
            return dict[key] as? String
        }
    }
    
    func integer(forKey key: String) -> Int {
        readWriteLock.withReadLock { () -> Int in
            return dict[key] as? Int ?? 0
        }
    }
    
    func int64(forKey key: String) -> Int64 {
        readWriteLock.withReadLock { () -> Int64 in
            return dict[key] as? Int64 ?? 0
        }
    }
    
    func float(forKey key: String) -> Float {
        readWriteLock.withReadLock { () -> Float in
            return dict[key] as? Float ?? 0
        }
    }
    
    func double(forKey key: String) -> Double {
        readWriteLock.withReadLock { () -> Double in
            return dict[key] as? Double ?? 0
        }
    }
    
    func bool(forKey key: String) -> Bool {
        readWriteLock.withReadLock { () -> Bool in
            return dict[key] as? Bool ?? false
        }
    }
    
    func set(_ value: String, forKey key: String) {
        readWriteLock.withWriteLock { () -> Void in
            dict[key] = value
            syncToFile()
        }
    }
    
    func set(_ value: Int, forKey key: String) {
        readWriteLock.withWriteLock { () -> Void in
            dict[key] = value
            syncToFile()
        }
    }
    
    func set(_ value: Int64, forKey key: String) {
        readWriteLock.withWriteLock { () -> Void in
            dict[key] = value
            syncToFile()
        }
    }
    
    func set(_ value: Float, forKey key: String) {
        readWriteLock.withWriteLock { () -> Void in
            dict[key] = value
            syncToFile()
        }
    }
    
    func set(_ value: Double, forKey key: String) {
        readWriteLock.withWriteLock { () -> Void in
            dict[key] = value
            syncToFile()
        }
    }
    
    func set(_ value: Bool, forKey key: String) {
        readWriteLock.withWriteLock { () -> Void in
            dict[key] = value
            syncToFile()
        }
    }
    
    private func syncToFile() {
        serialQueue.async {
            (self.dict as NSDictionary).write(to: self.fileUrl, atomically: true)
        }
    }
}
