//
//  AppState.swift
//  core-ios-sdk
//
//  Created by Atul Manwar on 14/06/18.
//  Copyright © 2018 www.hypertrack.com. All rights reserved.
//

import Foundation
import CoreTelephony

public protocol AbstractAppState: DeviceIdProtocol, DeviceDataProtocol, HeartbeatPingProtocol, HeartbeatInfoProtocol, AccountDetailsProtocol, SessionInfoProtocol {
    func getInstallationId() -> String
    var isPausedByUser: Bool { get set }
    var isAppInitialized: Bool { get set }
}

public typealias DeviceIdProtocol = GetDeviceIdProtocol & SetDeviceIdProtocol

public protocol GetDeviceIdProtocol: class {
    func getDeviceId() -> String
}

public protocol SetDeviceIdProtocol {
    func setDeviceId(_ id: String)
}

public typealias AccountDetailsProtocol = GetPublishableKeyProtocol & SetPublishableKeyProtocol & GetAccountIdProtocol & SetAccountIdProtocol

public typealias AccountAndDeviceDetailsProvider = GetPublishableKeyProtocol & GetDeviceIdProtocol & GetAccountIdProtocol & SetAccountIdProtocol

public protocol GetPublishableKeyProtocol: class {
    func getPublishableKey() -> String
}

public protocol SetPublishableKeyProtocol {
    func setPublishableKey(_ id: String)
}

public protocol GetAccountIdProtocol: class {
    func getAccountId() -> String
}

public protocol SetAccountIdProtocol {
    func setAccountId(_ id: String)
}

public protocol HeartbeatPingProtocol {
    func getHeartbeatLastPing() -> Date
    func setHeartbeatLastPing(date: Date)
}

public protocol HeartbeatInfoProtocol {
    func getHeartbeatInfo() -> HeartbeatInfo
    func saveHeartbeatInfo(info: HeartbeatInfo)
}

public protocol SessionInfoProtocol {
    func isSessionLaunchedInOffline() -> Bool
}

public final class AppState: AbstractAppState {
    fileprivate weak var dataStore: AbstractReadWriteDataStore?
    fileprivate weak var logger: AbstractLogger?
    fileprivate let installationIdKey = "key.appState.installationId"
    fileprivate let deviceIdKey = "key.appState.deviceId"
    fileprivate let accountIdKey = "key.appState.accountIdKey"
    fileprivate let pausedByUserKey = "key.appState.pausedByUser"
    fileprivate let heartbeatInfoKey = "key.appState.heartbeatInfo"
    fileprivate var deviceId: String
    fileprivate var publishableKey: String
    fileprivate var accountId: String
    fileprivate let installationId: String
    fileprivate var lastSessionInfo: LastSessionInfo? = nil
    
    public var isPausedByUser: Bool {
        get {
            return dataStore?.bool(forKey: pausedByUserKey) ?? false
        }
        set {
            dataStore?.set(newValue, forKey: pausedByUserKey)
        }
    }
    public var isAppInitialized: Bool = false
    
    public init(dataStore: AbstractReadWriteDataStore?, logger: AbstractLogger?) {
        self.dataStore = dataStore
        self.logger = logger
        if let deviceId = dataStore?.string(forKey: deviceIdKey) {
            self.deviceId = deviceId
        } else {
            deviceId = UIDevice.current.identifierForVendor?.uuidString ?? UUID().uuidString
            dataStore?.set(deviceId, forKey: deviceIdKey)
        }
        if let installationId = dataStore?.string(forKey: installationIdKey) {
            self.installationId = installationId
        } else {
            installationId = UIDevice.current.identifierForVendor?.uuidString ?? UUID().uuidString
            dataStore?.set(installationId, forKey: installationIdKey)
        }
        if let accountId = dataStore?.string(forKey: accountIdKey) {
            self.accountId = accountId
        } else {
            self.accountId = ""
        }
        self.publishableKey = ""
        self.lastSessionInfo = LastSessionInfo(lastPingTime: self.getHeartbeatLastPing(), currentStartTime: Date(), disconnectInterval: self.getHeartbeatInfo().disconnectInterval)

    }
    
    public func getAccountId() -> String {
        return accountId
    }
    
    public func setAccountId(_ id: String) {
        accountId = id
        dataStore?.set(accountId, forKey: accountIdKey)
    }

    public func getDeviceId() -> String {
        return deviceId
    }
    
    public func setDeviceId(_ id: String) {
        deviceId = id
        dataStore?.set(deviceId, forKey: deviceIdKey)
    }
    
    public func getPublishableKey() -> String {
        return publishableKey
    }
    
    public func setPublishableKey(_ id: String) {
        publishableKey = id
    }
    
    public func getInstallationId() -> String {
        return installationId
    }
    
    public func getHeartbeatLastPing() -> Date {
        if let date = dataStore?.object(forKey: Constant.Heartbeat.Key.lastSuccessTimeStamp) as? Date {
            return date
        }
        return Date()
    }
    
    public func setHeartbeatLastPing(date: Date) {
        dataStore?.set(date, forKey: Constant.Heartbeat.Key.lastSuccessTimeStamp)
    }
    
    public func getDeviceData() -> DeviceInfo {
        let deviceId = self.deviceId
        let timeZone = TimeZone.current.identifier
        let networkOprator = CTTelephonyNetworkInfo().subscriberCellularProvider?.carrierName ?? "unknown"
        let manufacturer = "apple"
        let deviceHardware = UIDevice.current.model
        let osName =  UIDevice.current.systemName
        let osVersion = UIDevice.current.systemVersion
        let appPackageName = Bundle.main.bundleIdentifier ?? ""
        var appVersion = ""
        
        let sdkVersion = getsdkVersion()
        
        if let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String {
            appVersion = version
        }
        
        let deviceData = DeviceInfo(deviceId: deviceId, timeZone: timeZone, networkOperator: networkOprator, manufacturer: manufacturer, deviceHardware: deviceHardware, osName: osName, osVersion: osVersion, appPackageName: appPackageName, appVersion: appVersion, sdkVersion: sdkVersion, recordedAt: Date())
        
        return deviceData
        
    }
    
    private func getBundle() -> Bundle? {
        let bundle = Bundle(for: HyperTrackCore.self)
        return bundle
    }
    
    private func getsdkVersion() -> String {
        if let bundle = self.getBundle() {
            if let dictionary = bundle.infoDictionary {
                if let version = dictionary["CFBundleShortVersionString"] as? String {
                    return version
                }
            }
        }
        return ""
    }
    
    public func getHeartbeatInfo() -> HeartbeatInfo {
        guard let data = dataStore?.data(forKey: heartbeatInfoKey) else { return HeartbeatInfo.default}
        do {
            return try JSONDecoder.hyperTrackDecoder.decode(HeartbeatInfo.self, from: data)
        } catch {
            logger?.logError("Unable to retrieve HeartBeatInfo in Defaults", context: Constant.Context.appState)
        }
        return HeartbeatInfo.default
    }
    
    public func saveHeartbeatInfo(info: HeartbeatInfo) {
        do {
            dataStore?.set(try JSONEncoder.hyperTrackEncoder.encode(info), forKey: heartbeatInfoKey)
        } catch {
            logger?.logError("Unable to save HeartBeatInfo in Defaults", context: Constant.Context.appState)
        }
    }
    
    public func isSessionLaunchedInOffline() -> Bool {
        return self.lastSessionInfo?.isPreviousSessionOffline() ?? false
    }
    
}
