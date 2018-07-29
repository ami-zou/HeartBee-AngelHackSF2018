//
//  ActivityData.swift
//  core-ios-sdk
//
//  Created by Ashish Asawa on 04/06/18.
//  Copyright © 2018 www.hypertrack.com. All rights reserved.
//

import Foundation
import CoreMotion
import CoreLocation

public struct ActivityServiceData: AbstractServiceData {
    let osActivity: CMMotionActivity
    let activityId: String
    let recordedDate: Date
    var data: ActivityData
    
    init(activityId: String, osActivity: CMMotionActivity, recordedDate: Date) {
        self.osActivity = osActivity
        self.activityId = activityId
        self.recordedDate = recordedDate
        self.data = ActivityData(value: ActivityServiceData.ActivityType(activity: osActivity))
    }
    
    public static func createActivity(fromType activityType: ActivityType) -> ActivityServiceData {
        var activity = ActivityServiceData(activityId: UUID().uuidString, osActivity: CMMotionActivity.init(), recordedDate: Date())
        activity.data = ActivityData(value: activityType)
        return activity
    }
    
    public func getType() -> EventType {
        return getEventType()
    }
    
    public func getRecordedAt() -> Date {
        return self.recordedDate
    }
    
    public func getId() -> String {
        return activityId
    }
    
    public func getJSONdata() -> String {
        //TODO: handle throw from here
        do {
            return try String(data: JSONEncoder.hyperTrackEncoder.encode(data), encoding: .utf8)!
        } catch {
            return ""
        }
    }
    
    private func getEventType() -> EventType {
        return EventType.activityChange
    }
    
    public enum ActivityType: String, Codable {
        case stop = "stop"
        case walk = "walk"
        case run = "run"
        case cycle = "cycle"
        case drive = "drive"
        case moving = "moving"
        case unsupported = "unsupported"
        
        var isSupported: Bool {
            switch self {
            case .unsupported:
                return false
            default:
                return true
            }
        }
        
        public init(activity: CMMotionActivity) {
            if activity.walking {
                self = .walk
            } else if activity.running {
                self = .run
            } else if activity.automotive {
                self = .drive
            } else if activity.cycling {
                self = .cycle
            } else if activity.stationary {
                self = .stop
            } else if activity.unknown {
                self = .moving
            } else {
                self = .unsupported
            }
        }
    }
}

public struct ActivityData: Codable {
    let value: String
    var type: ActivityServiceData.ActivityType? {
        return ActivityServiceData.ActivityType(rawValue: value)
    }
    
    enum Keys: String, CodingKey {
        case value = "value"
    }
    
    init(value: ActivityServiceData.ActivityType) {
        self.value = value.rawValue
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: Keys.self)
        value = try container.decode(String.self, forKey: .value)
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: Keys.self)
        try container.encode(value, forKey: .value)
    }
}
