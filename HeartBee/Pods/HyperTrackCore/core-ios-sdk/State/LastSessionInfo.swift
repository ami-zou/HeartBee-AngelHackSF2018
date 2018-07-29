//
//  LastSessionInfo.swift
//  HyperTrackCore
//
//  Created by Ashish Asawa on 16/07/18.
//  Copyright © 2018 www.hypertrack.com. All rights reserved.
//

import Foundation

struct LastSessionInfo {
    
    let lastPingTime: Date
    let currentStartTime: Date
    let disconnectInterval: TimeInterval
    
    func isPreviousSessionOffline() -> Bool {
        var wasOffline      = false
        let timeInterval    = self.currentStartTime.timeIntervalSince(lastPingTime)
        if timeInterval >= disconnectInterval {
            wasOffline = true
        }
        return wasOffline
    }
    
    
}
