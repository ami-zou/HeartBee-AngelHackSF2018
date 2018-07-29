//
//  Constants.swift
//  core-ios-sdk
//
//  Created by Atul Manwar on 01/06/18.
//  Copyright © 2018 www.hypertrack.com. All rights reserved.
//

import Foundation

enum Constant {
    static let namespace = "com.hypertrack.sdk.core"
    
    enum Notification {
        enum DataStore {
            
        }
        enum Database {
            enum DataAvailableEvent {
                static let key = "database.dataAvailable"
                static let name = Constant.namespace + key
            }
        }
        enum Transmission {
            enum SendDataEvent {
                static let key = "transmission.events.sendData"
                static let name = Constant.namespace + key
            }
            enum DataSentEvent {
                static let key = "transmission.events.dataSent"
                static let name = Constant.namespace + key
            }
        }
        enum Health {
            
        }
        enum Config {
            enum ConfigChangedEvent {
                static let key = "config.changed"
                static let name = Constant.namespace + key
            }
        }
        enum Dispatch {
            enum TypeChangedEvent {
                static let key = "dispatch.typeChanged"
                static let name = Constant.namespace + key
            }
        }
        enum Activity {
            enum PermissionChangedEvent {
                static let key = "activity.permissionChanged"
                static let name = Constant.namespace + key
            }
            enum ActivityChangedEvent {
                static let key = "activity.changed"
                static let name = Constant.namespace + key
            }
        }
        enum Location {
            enum PermissionChangedEvent {
                static let key = "location.permissionChanged"
                static let name = Constant.namespace + key
            }
        }
        enum Network {
            enum ReachabilityEvent {
                static let key = "network.reachability"
                static let name = Constant.namespace + key
            }
        }
        enum Tracking {
            enum Pause {
                static let key = "tacking.pause"
                static let name = Constant.namespace + key
            }
            enum Resume {
                static let key = "tacking.resume"
                static let name = Constant.namespace + key
            }
        }
        enum HeartbeatService {
            enum StatusChangedEvent {
                static let key      = "heartbeatService.status"
                static let name     = Constant.namespace + key
            }
        }
    }
    
    enum Context {
        static let dataStore = 0
        static let database = 1
        static let config = 2
        static let network = 3
        static let eventBus = 4
        static let fileStorage = 5
        static let location = 6
        static let activity = 7
        static let health = 8
        static let heartbeat = 9
        static let services = 10
        static let initPipeline = 11
        static let collectionPipeline = 12
        static let transmissionPipeline = 13
        static let dispatch = 14
        static let lifecycle = 15
        static let pipelineStep = 16
        static let appState = 17
    }
    
    enum Config {
        enum DataStore {
            static let dataStoreSuitName = "com.hypertrack.sdk.core"
        }
        enum Network {
            static let timeoutInterval: Double = 10
            static let retryCount: Int = 3
            static let host: String = "https://prodapi.hypertrack.com"
        }
        enum Dispatch {
            static let frequency: Double = 10
            static let tolerance: Int = 10
            static let debounce: Double = 2
            static let throttle: Double = 1
        }
        enum Transmission {
            static let batchSize: UInt = 50
        }
        enum Services {
            static let types: [Int] = [2, 0, 1]
        }
        enum Location {
            static let onlySignificantLocationUpdates: Bool = false
            static let deferredLocationUpdatesDistance: Double = 0
            static let deferredLocationUpdatesTimeout: Double = 0
            static let backgroundLocationUpdates: Bool = true
            static let distanceFilter: Double = 50
            static let distanceFilterForLowSpeed: Double = 10
            static let desiredAccuracy: Double = 1
            static let permissionType = 0
            static let showsBackgroundLocationIndicator = false
            static let pausesLocationUpdatesAutomatically = false
        }
        enum Collection {
            static let isFiltering: Bool = false
        }
        enum Heartbeat {
            static let pingInterval:        TimeInterval            = 180
            static let retryCount:          Int                     = 2
            static let retryInterval:       TimeInterval            = 60
            static let disconnectInterval:  TimeInterval            = 600
            static let toPing:              Bool                    = true
        }
    }

    enum EventValue {
        enum Activity {
            static let stop     = "stop"
            static let walk     = "walk"
            static let run      = "run"
            static let cycle    = "cycle"
            static let drive    = "drive"
            static let unknown  = "unknown"
        }
    }
    
    enum ServerKeys {
        enum Event {
            static let id           = "id"
            static let deviceId     = "device_id"
            static let type         = "type"
            static let data         = "data"
            static let events       = "events"
            static let recordedAt   = "recorded_at"
        }
        enum DeviceInfo {
            static let deviceId             = "device_id"
            static let timeZone             = "timezone"
            static let networkOperator      = "network_operator"
            static let deviceManufacturer   = "device_manufacturer"
            static let deviceHardware       = "device_hardware"
            static let osName               = "os_name"
            static let osVersion            = "os_version"
            static let appPackageName       = "app_package_name"
            static let appVersion           = "app_version"
            static let sdkVersion           = "sdk_version"
            static let recordedAt           = "recorded_at"
            static let hasPlayServices      = "has_play_services"

        }
        enum Heartbeat {
            static let lastPingTime         = "Time_Since_Last_Ping"
        }
        
    }
    
    enum Database {
        static let name = "database.sqlite"
        enum TableName {
            static let onlineEvent  = "eventOnline"
            static let offlineEvent = "eventOffline"
        }
    }
    
    enum Heartbeat {
        static let url = "http://35.173.243.67:9000/ping"
        enum Key {
            static let lastSuccessTimeStamp     = "heartbeat.key.lastSuccessTimeStamp"
        }
    }
    
    enum Health {
        enum Key {
            static let tracking                         = "health.key.tracking"
            static let location                         = "health.key.location"
            static let activity                         = "health.key.activity"
            static let batteryLevel                     = "health.key.batteryLevel"
            static let batteryState                     = "health.key.batteryState"
            static let sdkRunningState                  = "health.key.sdkRunningState"
            static let deviceBoot                       = "health.key.deviceBoot"
        }
        enum Tracking: String {
            case pause              = "tracking.paused"
            case resume             = "tracking.resumed"
        }
        enum LocationService: String {
            case disabled               =  "location.disabled"
            case enabled                =  "location.enabled"
        }
        enum LocationPermission: String {
            case denied                 =  "location.permission_denied"
            case granted                =  "location.permission_granted"
        }
        enum Activity: String {
            case disabled               = "activity.permission_denied"
            case enabled                = "activity.permission_granted"
        }
        enum BatteryLevel: String {
            case low                = "battery.low"
            case normal             = "battery.back_to_normal"
        }
        enum BatteryState: String {
            case charging           = "battery_charging"
            case discharging        = "battery_discharging"
        }
        enum SdkRunningState: String {
            case killed           = "sdk.killed"
            case restarted        = "sdk.restarted"
        }
        enum DeviceBoot: String {
            case switchOff        = "device.switched_off"
            case switchOn         = "device.switched_on"
            }
    }
    static let lowBatteryValue: Float = 0.2
    
}

public enum EventType: String {
    case activityChange = "activity.change"
    case locationChange = "location.change"
    case healthChange   = "health.change"
    case deviceReconnected = "device.reconnected"
}

public enum EventCollectionType {
    case online
    case offline
    
    func tableName() -> String {
        switch self {
            case .online:       return Constant.Database.TableName.onlineEvent
            case .offline:      return Constant.Database.TableName.offlineEvent
        }
    }
}

