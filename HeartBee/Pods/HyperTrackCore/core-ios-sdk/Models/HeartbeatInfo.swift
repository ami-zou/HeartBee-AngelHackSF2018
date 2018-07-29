//
//  HeartbeatInfo.swift
//  HyperTrackCore
//
//  Created by Ashish Asawa on 11/07/18.
//  Copyright © 2018 www.hypertrack.com. All rights reserved.
//

import Foundation

public struct HeartbeatInfo: Codable {
    let pingInterval:       TimeInterval
    let retryCount:         Int
    let retryInterval:      TimeInterval
    let disconnectInterval: TimeInterval
    
    public init() {
        self.pingInterval           = Constant.Config.Heartbeat.pingInterval
        self.retryCount             = Constant.Config.Heartbeat.retryCount
        self.retryInterval          = Constant.Config.Heartbeat.retryInterval
        self.disconnectInterval     = Constant.Config.Heartbeat.disconnectInterval
    }
    
    enum Keys: String, CodingKey {
        case pingInterval       = "ping_interval"
        case retryCount         = "retry_count"
        case retryInterval      = "retry_interval"
        case disconnectInterval = "disconnect_interval"
    }
    
    public init(from decoder: Decoder) throws {
        let container   = try decoder.container(keyedBy: Keys.self)
        pingInterval    = (try? container.decode(Double.self, forKey: .pingInterval)) ?? Constant.Config.Heartbeat.pingInterval
        retryCount      = (try? container.decode(Int.self, forKey: .retryCount)) ?? Constant.Config.Heartbeat.retryCount
        retryInterval   = (try? container.decode(Double.self, forKey: .retryInterval)) ?? Constant.Config.Heartbeat.retryInterval
        disconnectInterval = (try? container.decode(Double.self, forKey: .disconnectInterval)) ?? Constant.Config.Heartbeat.disconnectInterval
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: Keys.self)
        try container.encode(pingInterval,          forKey: .pingInterval)
        try container.encode(retryCount,            forKey: .retryCount)
        try container.encode(retryInterval,         forKey: .retryInterval)
        try container.encode(disconnectInterval,    forKey: .disconnectInterval)
    }
    
    static var `default` : HeartbeatInfo {
        return HeartbeatInfo.init()
    }
    
}
