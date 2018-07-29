//
//  HealthServiceData.swift
//  HyperTrackCore
//
//  Created by Ashish Asawa on 21/06/18.
//  Copyright © 2018 www.hypertrack.com. All rights reserved.
//

import Foundation

typealias HealthKeyValue = (key: String, value: String)

struct HealthServiceData: AbstractServiceData {

    let healthId: String
    let recordedDate: Date
    var data: HealthData
    
    init(healthType: HealthType, recordedDate: Date) {
        self.healthId       = UUID().uuidString
        self.recordedDate   = recordedDate
        self.data           = HealthData(value: healthType)
    }
    
    func getType() -> EventType {
        return EventType.healthChange
    }
    
    func getId() -> String {
        return healthId
    }
    
    func getRecordedAt() -> Date {
        return recordedDate
    }
    
    func getJSONdata() -> String {
        //TODO: handle throw from here
        do {
            return try String(data: JSONEncoder.hyperTrackEncoder.encode(data), encoding: .utf8)!
        } catch {
            return ""
        }
    }
    
}

protocol HealthKeyValueProtocol {
    func keyValue() -> (HealthKeyValue)
}

public enum HealthType: String, Codable, HealthKeyValueProtocol {
    //TODO: Grouping of events
    
    case trackingPaused                 = "tracking.paused"
    case trackingResumed                = "tracking.resumed"
    
    case sdkKilled                      = "sdk.killed"
    case sdkRestarted                   = "sdk.restarted"
    
    case gpsLost                        = "gps.lost"
    case gpsFound                       = "gps.found"
    
    case locationDisabled               = "location.disabled"
    case locationEnabled                = "location.enabled"
    case locationPermissionDenied       = "location.permission_denied"
    case locationPermissionGranted      = "location.permission_granted"
    
    case activityDisabled               = "activity.permission_denied"
    case activityEnabled                = "activity.permission_granted"
    
    case airplaneModeOn                 = "airplane_mode.on"
    case airplaneModeOff                = "airplane_mode.off"
    
    case batteryLow                     = "battery.low"
    case batteryNormal                  = "battery.back_to_normal"
    
    case batteryCharging                = "battery.charging"
    case batteryDischarging             = "battery.discharging"
    
    case deviceSwitchedOff              = "device.switched_off"
    case deviceSwitchedOn               = "device.switched_on"
    
    func keyValue() -> (HealthKeyValue) {
        switch self {
            
        case .trackingPaused:               return(Constant.Health.Key.tracking, Constant.Health.Tracking.pause.rawValue)
        case .trackingResumed:              return(Constant.Health.Key.tracking, Constant.Health.Tracking.resume.rawValue)
        case .locationDisabled:             return(Constant.Health.Key.location, Constant.Health.LocationService.disabled.rawValue)
        case .locationEnabled:              return(Constant.Health.Key.location, Constant.Health.LocationService.enabled.rawValue)
        case .locationPermissionDenied:     return(Constant.Health.Key.location, Constant.Health.LocationPermission.denied.rawValue)
        case .locationPermissionGranted:    return(Constant.Health.Key.location, Constant.Health.LocationPermission.granted.rawValue)
        case .activityDisabled:             return(Constant.Health.Key.activity, Constant.Health.Activity.disabled.rawValue)
        case .activityEnabled:              return(Constant.Health.Key.activity, Constant.Health.Activity.enabled.rawValue)
        case .batteryLow:                   return(Constant.Health.Key.batteryLevel, Constant.Health.BatteryLevel.low.rawValue)
        case .batteryNormal:                return(Constant.Health.Key.batteryLevel, Constant.Health.BatteryLevel.normal.rawValue)
        case .batteryCharging:              return(Constant.Health.Key.batteryState, Constant.Health.BatteryState.charging.rawValue)
        case .batteryDischarging:           return(Constant.Health.Key.batteryState, Constant.Health.BatteryState.discharging.rawValue)
        case .sdkKilled:                    return(Constant.Health.Key.sdkRunningState, Constant.Health.SdkRunningState.killed.rawValue)
        case .sdkRestarted:                 return(Constant.Health.Key.sdkRunningState, Constant.Health.SdkRunningState.restarted.rawValue)
        case .deviceSwitchedOn:             return(Constant.Health.Key.deviceBoot, Constant.Health.DeviceBoot.switchOn.rawValue)

        default:
            //TODO: Exhaustive switch
            return ("unknown", "unknown")
        }
    }
    
}


struct HealthData: Codable {
    let value: String
    
    enum Keys: String, CodingKey {
        case value = "value"
    }
    
    init(value: HealthType) {
        self.value = value.rawValue
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: Keys.self)
        value = try container.decode(String.self, forKey: .value)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: Keys.self)
        try container.encode(value, forKey: .value)
    }
}

