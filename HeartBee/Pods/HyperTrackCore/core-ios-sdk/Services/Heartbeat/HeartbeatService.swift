//
//  HeartbeatService.swift
//  HyperTrackCore
//
//  Created by Ashish Asawa on 19/06/18.
//  Copyright © 2018 www.hypertrack.com. All rights reserved.
//

import Foundation
import os

final class HeartbeatService {
    
    private var backgroundTaskIdentifier : UIBackgroundTaskIdentifier = 0
    fileprivate weak var apiClient:     AbstractAPIClient?
    fileprivate weak var appState:      AbstractAppState?
    fileprivate weak var config:        HeartbeatServiceConfig?
    fileprivate weak var eventBus:      AbstractEventBus?
    fileprivate weak var logger:        AbstractLogger?
    
    fileprivate var  info: HeartbeatInfo
    
    var repeatTimer: HeartbeatRepeatingTimer?
    var lastPingTime: Int = 0
    var pingCount: Int  = 0
    var status: Status = .unknown {
        didSet {
            if oldValue != status {
                self.eventBus?.post(name: Constant.Notification.HeartbeatService.StatusChangedEvent.name, userInfo: [Constant.Notification.HeartbeatService.StatusChangedEvent.key: status])
            }
        }
    }
    
    enum Status {
        case pingFail
        case disconnect
        case reconnect
        case unknown
        
        var isConnected: Bool {
            switch self {
            case .reconnect:
                return true
            default:
                return false
            }
        }
    }
    
    public convenience init() {
        self.init(config: nil, eventBus: nil, appState: nil, apiClient: nil, logger: nil, info: HeartbeatInfo.default)
    }
    
    //TODO: Config integration
    public init(config: HeartbeatServiceConfig?, eventBus: AbstractEventBus?, appState: AbstractAppState?, apiClient: AbstractAPIClient?, logger:  AbstractLogger?, info: HeartbeatInfo)  {
        self.config         = config
        self.apiClient      = apiClient
        self.appState       = appState
        self.eventBus       = eventBus
        self.info           = info
        self.logger       = logger
        eventBus?.addObserver(self, selector: #selector(onAppBackground(_:)), name: Notification.Name.UIApplicationDidEnterBackground.rawValue)
        eventBus?.addObserver(self, selector: #selector(updateConfig(_ :)), name: Constant.Notification.Config.ConfigChangedEvent.name)
        eventBus?.addObserver(self, selector: #selector(reachabilityChanged(_ :)), name: Constant.Notification.Network.ReachabilityEvent.name)
    }
    
    // MARK: Notification Received Methods
    
    @objc func updateConfig(_ notification: Notification) {
        guard let _ = config else {
            return
        }
        //TODO: Config change handling
    }
    
    @objc func onAppBackground(_ notification: Notification) {
        stopService()
        self.backgroundTaskIdentifier = UIApplication.shared.beginBackgroundTask(withName: "HTHeartbeatService") {
            self.endBackgroundTask()
        }
        startService()
    }
    
    private func endBackgroundTask() {
        debugPrint("HT Background Heartbeat service ended.")
        UIApplication.shared.endBackgroundTask(self.backgroundTaskIdentifier)
        self.backgroundTaskIdentifier = UIBackgroundTaskInvalid
    }
    
    @objc func reachabilityChanged(_ notification: Notification) {
        guard let value = notification.userInfo?[Constant.Notification.Network.ReachabilityEvent.key] as? Bool, value else { return }
        stopService()
        startService()
    }
    
    // MARK: Public API Methods
    
    func startService() {
        let toPing = config?.heartbeat.toPing ?? Constant.Config.Heartbeat.toPing
        if toPing == false {
            return
        }
        let time = info.pingInterval
        if self.repeatTimer == nil {
            self.repeatTimer = HeartbeatRepeatingTimer(timeInterval: time)
        }
        fireTimer()
    }
    
    func stopService() {
        self.repeatTimer?.suspend()
    }
    
    private func fireTimer() {
        self.repeatTimer?.eventHandler = { [weak self] in
            self?.pingServer()
        }
        self.repeatTimer?.resume()
    }
    
    private func resetTimer(timeInterval: TimeInterval) {
        if let currentTimeInterval = self.repeatTimer?.timeInterval {
            if currentTimeInterval != timeInterval {
                self.repeatTimer?.reset(timeInterval: timeInterval)
            }
        }
    }
    
    private func pingServer() {
        //TODO: Dispatch_group
        guard let appState = self.appState else {
            return
        }
        let date = appState.getHeartbeatLastPing()
        let pingDate = Date()
        var timeInterval = pingDate.timeIntervalSince(date)
        if timeInterval <= 0 {
            timeInterval = 0
        }
        lastPingTime = Int(timeInterval)
        //TODO: Reachability Test before making request
        self.apiClient?.makeRequest(ApiRouter.heartbeatPing(appState.getDeviceId(), lastPingTime)).continueWith(continuation: { [weak self] (task) -> Void in
            guard let `self` = self else { return }
            let handler     = HeartbeatServiceResponseHandler(task: task, appState: appState, eventBus: self.eventBus, logger: self.logger)
            let result      = handler.nextPing(previousPingDate: pingDate, previousPingTimeInterval: timeInterval, info: self.info)
            self.status     = result.status
            self.resetTimer(timeInterval: result.timeInterval)
        })
    }

}
