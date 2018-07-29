//
//  DataStore.swift
//  core-ios-sdk
//
//  Created by Atul Manwar on 01/06/18.
//  Copyright © 2018 www.hypertrack.com. All rights reserved.
//

import Foundation

public protocol AbstractReadDataStore {
    func object(forKey defaultName: String) -> Any?
    func string(forKey defaultName: String) -> String?
    func array(forKey defaultName: String) -> [Any]?
    func dictionary(forKey defaultName: String) -> [String : Any]?
    func data(forKey defaultName: String) -> Data?
    func stringArray(forKey defaultName: String) -> [String]?
    func integer(forKey defaultName: String) -> Int
    func float(forKey defaultName: String) -> Float
    func double(forKey defaultName: String) -> Double
    func bool(forKey defaultName: String) -> Bool
}

public protocol AbstractWriteDataStore {
    func set(_ value: Any?, forKey defaultName: String)
    func removeObject(forKey defaultName: String)
    func deleteAllValues()
    func synchronize()
}

public protocol AbstractReadWriteDataStore: class, AbstractReadDataStore, AbstractWriteDataStore {
}

public final class ReadWriteDataStoreWrapper {
    internal (set) lazy var defaults: AbstractReadWriteDataStore = {
        return SDKUserDefaults(logger: logger, config: config)
    }()
    
    fileprivate weak var logger: AbstractLogger?
    fileprivate weak var config: AbstractDataStoreConfig?
    
    public init(logger: AbstractLogger?, config: AbstractDataStoreConfig) {
        self.logger = logger
        self.config = config
    }
}

public final class SDKUserDefaults: AbstractReadWriteDataStore {
    private var suiteName: String {
        return config?.dataStore.dataStoreSuitName ?? Constant.Config.DataStore.dataStoreSuitName
    }
    private var defaults: UserDefaults?
    fileprivate weak var config: AbstractDataStoreConfig?
    fileprivate weak var logger: AbstractLogger?
    
    public convenience init(logger: AbstractLogger?, config: AbstractDataStoreConfig?) {
        self.init()
        self.logger = logger
        self.config = config
        if defaults == nil {
            logger?.logError("Unable to instantiate UserDefaults data store", context: Constant.Context.dataStore)
        }
    }
    
    public init() {
        self.defaults = UserDefaults(suiteName: suiteName)
    }
}

extension SDKUserDefaults: AbstractReadDataStore {
    public func object(forKey defaultName: String) -> Any? {
        return defaults?.object(forKey: defaultName)
    }
    
    public func string(forKey defaultName: String) -> String? {
        return defaults?.string(forKey: defaultName)
    }
    
    public func array(forKey defaultName: String) -> [Any]? {
        return defaults?.array(forKey: defaultName)
    }
    
    public func dictionary(forKey defaultName: String) -> [String: Any]? {
        return defaults?.dictionary(forKey: defaultName)
    }
    
    public func data(forKey defaultName: String) -> Data? {
        return defaults?.data(forKey: defaultName)
    }
    
    public func stringArray(forKey defaultName: String) -> [String]? {
        return  defaults?.stringArray(forKey: defaultName)
    }
    
    public func integer(forKey defaultName: String) -> Int {
        return defaults?.integer(forKey: defaultName) ?? 0
    }
    
    public func float(forKey defaultName: String) -> Float {
        return defaults?.float(forKey: defaultName) ?? 0
    }
    
    public func double(forKey defaultName: String) -> Double {
        return defaults?.double(forKey: defaultName) ?? 0
    }
    
    public func bool(forKey defaultName: String) -> Bool {
        return defaults?.bool(forKey: defaultName) ?? false
    }
    
    public func url(forKey defaultName: String) -> URL? {
        return defaults?.url(forKey: defaultName)
    }
    
    public func synchronize() {
        defaults?.synchronize()
    }
}

extension SDKUserDefaults: AbstractWriteDataStore {
    public func set(_ value: Any?, forKey defaultName: String) {
        defaults?.set(value, forKey: defaultName)
        defaults?.synchronize()
    }
    
    public func removeObject(forKey defaultName: String) {
        defaults?.removeObject(forKey: defaultName)
        defaults?.synchronize()
    }
    
    public func deleteAllValues() {
        defaults?.removePersistentDomain(forName: suiteName)
        defaults?.synchronize()
    }
}
