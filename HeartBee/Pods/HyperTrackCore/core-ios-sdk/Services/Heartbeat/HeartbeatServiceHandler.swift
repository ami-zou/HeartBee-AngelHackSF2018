//
//  HeartbeatServiceHandler.swift
//  HyperTrackCore
//
//  Created by Ashish Asawa on 13/07/18.
//  Copyright © 2018 www.hypertrack.com. All rights reserved.
//

import Foundation

typealias HeartbeatServiceHandlerResult = (timeInterval: TimeInterval, status: HeartbeatService.Status)

struct HeartbeatServiceResponseHandler {
    let task:              Task<Response>
    weak var appState:      AbstractAppState?
    weak var eventBus:      AbstractEventBus?
    weak var logger:        AbstractLogger?
    
    func nextPing(previousPingDate pingDate: Date, previousPingTimeInterval timeInterval: TimeInterval, info: HeartbeatInfo) -> HeartbeatServiceHandlerResult {
        var result: HeartbeatServiceHandlerResult = (0, HeartbeatService.Status.unknown)
        if let error = task.error {
            result.timeInterval = info.retryInterval
            if timeInterval >= info.disconnectInterval {
                result.status = .disconnect
            } else {
                result.status = .pingFail
            }
            logger?.logError("HeartbeatService failed because \(error.coreErrorDescription)", context: Constant.Context.heartbeat)
        } else if let _ = task.result {
            appState?.setHeartbeatLastPing(date: pingDate)
            result.status = .reconnect
            result.timeInterval = info.pingInterval
            logger?.logDebug("HeartbeatService ping succeeded", context: Constant.Context.heartbeat)
        }
        return result
    }
}
