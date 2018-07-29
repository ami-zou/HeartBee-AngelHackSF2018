//
//  HealthService.swift
//  HyperTrackCore
//
//  Created by Ashish Asawa on 21/06/18.
//  Copyright © 2018 www.hypertrack.com. All rights reserved.
//

import Foundation

final class HealthService: AbstractService {
    fileprivate let sdkKilledTimestampKey   = "hypertrack.core.health.sdkKilled.timestamp"
    fileprivate let bootTimestampKey        = "hypertrack.core.health.bootup.timestamp"
    weak private var dataStore: AbstractReadWriteDataStore?
    weak private var appState:  AbstractAppState?
    
    private var batteryLevel: Float {
        return UIDevice.current.batteryLevel
    }
    
    private var batteryState: UIDeviceBatteryState {
        return UIDevice.current.batteryState
    }
    
    init(withCollectionProtocol collectionProtocol: AbstractCollectionPipeline?, eventBus: AbstractEventBus?, dataStore: AbstractReadWriteDataStore?, appState: AbstractAppState?) {
        self.collectionProtocol = collectionProtocol
        self.eventBus           = eventBus
        self.dataStore          = dataStore
        self.appState           = appState
        // tracking change following irrespective of service running or not.
        addObserverForTracking()
    }
    
    deinit {
        self.eventBus?.removeObserver(self)
    }
    
    // MARK: Battery Related Methods
    private func sendBatteryEvents() {
        sendBatteryLevelEvent()
//        sendBatteryStateEvent()
    }
    
    private func sendBatteryLevelEvent() {
        /*
         * first time sending only low battery event,
         * after that sending every change event.
         */
        let currentBattery  = batteryLevel
        guard currentBattery >= 0 else {
            // sometimes, value can come as -1.
            return
        }
        let type = getTypeFromBatteryLevel(level: currentBattery)
        if let _ = self.dataStore?.string(forKey: Constant.Health.Key.batteryLevel) {
            checkInDataStore(forType: type)
        } else {
            // no saved value
            if type == .batteryLow {
                checkInDataStore(forType: type)
            }
        }
    }
    
    private func getTypeFromBatteryLevel(level: Float) -> HealthType {
        var type = HealthType.batteryNormal
        if level <= Constant.lowBatteryValue {
            type = .batteryLow
        }
        return type
    }
    
//    private func sendBatteryStateEvent() {
//        let type = getTypeFromBatteryState(state: batteryState)
////        self.dataStore?.set(keyValue.value, forKey: keyValue.key)
//        checkInDataStore(forType: type)
//    }
    
    private func getTypeFromBatteryState(state: UIDeviceBatteryState) -> HealthType {
        switch state {
            case .unplugged, .unknown:         return HealthType.batteryDischarging
            case .charging, .full:             return HealthType.batteryCharging
        }
    }
    
    @objc private func batteryLevelChanged(_ notif: Notification) {
//        debugPrint(notif.debugDescription)
        sendBatteryLevelEvent()
    }
    
    // MARK: Activity Related Methods
    @objc private func activityPermissionChanged(_ notif: Notification) {
        guard let accessLevel = notif.userInfo?[Constant.Notification.Activity.PermissionChangedEvent.key] as? PrivateDataAccessLevel else {
            return
        }
        guard let type = self.getTypeFromActivityPermission(accessLevel: accessLevel) else {
            return
        }
        checkInDataStore(forType: type)
    }
    
    private func getTypeFromActivityPermission(accessLevel: PrivateDataAccessLevel) -> HealthType? {
        if accessLevel == .granted {
            return HealthType.activityEnabled
        } else if accessLevel == .denied {
            return HealthType.activityDisabled
        }
        return nil
    }
    
    // MARK: Location Related Methods
    @objc private func locationPermissionChanged(_ notif: Notification) {
        guard let accessLevel = notif.userInfo?[Constant.Notification.Location.PermissionChangedEvent.key] as? PrivateDataAccessLevel else {
            return
        }
        let savedValue  = self.dataStore?.string(forKey: Constant.Health.Key.location) ?? ""
        var previousAccessLevel: PrivateDataAccessLevel? = nil
        if savedValue == Constant.Health.LocationService.disabled.rawValue {
            previousAccessLevel = PrivateDataAccessLevel.restricted
        }
        guard let type = self.getTypeFromLocationPermission(accessLevel: accessLevel, previousAccessLevel: previousAccessLevel) else {
            return
        }
        checkInDataStore(forType: type)
    }
    
    private func getTypeFromLocationPermission(accessLevel: PrivateDataAccessLevel, previousAccessLevel: PrivateDataAccessLevel?) -> HealthType? {
        switch accessLevel {
            case .denied:                                               return HealthType.locationPermissionDenied
            case .granted, .grantedAlways, .grantedWhenInUse:
                if let previousAL = previousAccessLevel, previousAL == PrivateDataAccessLevel.restricted {
                    return HealthType.locationEnabled
                } else {
                    return HealthType.locationPermissionGranted
                }
            case .restricted:                                           return HealthType.locationDisabled
            case .undetermined:                                         return HealthType.locationEnabled
            default:                                                    return nil
        }
    }
    
    // MARK: Tracking Related Methods
    @objc private func pauseTrackingEvent(_ notif: Notification) {
        checkInDataStore(forType: HealthType.trackingPaused)
    }
    
    @objc private func resumeTrackingEvent(_ notif: Notification) {
        checkInDataStore(forType: HealthType.trackingResumed)
    }
    
    // MARK: SDK Restart/Kill Related Methods
    @objc private func appTerminatedEvent(_ notif: Notification) {
        let keyValue = HealthType.sdkKilled.keyValue()
        dataStore?.set(keyValue.value, forKey: keyValue.key)
        dataStore?.set(Date(), forKey: sdkKilledTimestampKey)
    }

    private func sendAppLauncedEvent() {
        let keyValue = HealthType.sdkKilled.keyValue()
        if let savedValue = dataStore?.string(forKey: keyValue.key), savedValue == keyValue.value, let date = dataStore?.object(forKey: sdkKilledTimestampKey) as? Date {
            guard let appState = self.appState else {
                return
            }
            if appState.isSessionLaunchedInOffline() {
                sendEvent(forType: HealthType.sdkKilled, date: date, keyValue: keyValue, inCollectionType: .offline)
            } else {
                sendEvent(forType: HealthType.sdkKilled, date: date, keyValue: keyValue)
            }
        }
        checkInDataStore(forType: HealthType.sdkRestarted)
    }

    // MARK: Device Switch On Methods
    private func sendDeviceSwithOnEvent() {
        let keyValue    = HealthType.deviceSwitchedOn.keyValue()
        let upTime      = ProcessInfo.processInfo.systemUptime
        let bootUpTime  = Date(timeIntervalSinceNow: -upTime)
        if let savedBootUpTime = dataStore?.object(forKey: bootTimestampKey) as? Date {
            let difference = bootUpTime.timeIntervalSince(savedBootUpTime)
            if abs(difference) > 10 {
                // boot up time is changed
                sendBootUp(forDate: bootUpTime, keyValue: keyValue)
            }
        } else {
            // First Time
            sendBootUp(forDate: bootUpTime, keyValue: keyValue)
        }
    }
    
    private func sendBootUp(forDate date: Date, keyValue: HealthKeyValue) {
        dataStore?.set(date, forKey: bootTimestampKey)
        sendEvent(forType: HealthType.deviceSwitchedOn, date: date, keyValue: keyValue)
    }
    
    // MARK: Data Store Methods
    private func checkInDataStore(forType type: HealthType) {
        let keyValue    = type.keyValue()
        let savedValue  = self.dataStore?.string(forKey: keyValue.key) ?? ""
        if savedValue != keyValue.value {
            sendEvent(forType: type, keyValue: keyValue)
        }
    }
    
    // MARK: Add Observers
    private func addObservers() {
        addObserverForBattery()
        addObserverForActivity()
        addObserverForLocation()
        addObserverForAppStates()
    }
    
    private func removeObservers() {
        self.eventBus?.removeObserver(self, name: Notification.Name.UIDeviceBatteryLevelDidChange.rawValue)
        self.eventBus?.removeObserver(self, name: Constant.Notification.Activity.PermissionChangedEvent.name)
        self.eventBus?.removeObserver(self, name: Constant.Notification.Location.PermissionChangedEvent.name)
        self.eventBus?.removeObserver(self, name: NSNotification.Name.UIApplicationWillTerminate.rawValue)
    }
    
    private func addObserverForBattery() {
        UIDevice.current.isBatteryMonitoringEnabled = true
//        self.eventBus?.addObserver(self, selector: #selector(batteryStateChanged(_:)), name: Notification.Name.UIDeviceBatteryStateDidChange.rawValue)
        self.eventBus?.addObserver(self, selector: #selector(batteryLevelChanged(_:)), name: Notification.Name.UIDeviceBatteryLevelDidChange.rawValue)
    }
    
    private func addObserverForActivity() {
        self.eventBus?.addObserver(self, selector: #selector(activityPermissionChanged(_:)), name: Constant.Notification.Activity.PermissionChangedEvent.name)
    }
    
    private func addObserverForLocation() {
        self.eventBus?.addObserver(self, selector: #selector(locationPermissionChanged(_:)), name: Constant.Notification.Location.PermissionChangedEvent.name)
    }
    
    private func addObserverForTracking() {
        self.eventBus?.addObserver(self, selector: #selector(pauseTrackingEvent(_:)), name: Constant.Notification.Tracking.Pause.name)
        self.eventBus?.addObserver(self, selector: #selector(resumeTrackingEvent(_:)), name: Constant.Notification.Tracking.Resume.name)
    }
    
    private func addObserverForAppStates() {
        self.eventBus?.addObserver(self, selector: #selector(appTerminatedEvent(_:)), name: NSNotification.Name.UIApplicationWillTerminate.rawValue)
    }
    
    // MARK: Send Event Method
    private func sendEvent(forType type: HealthType, date: Date = Date(), keyValue: HealthKeyValue) {
        self.dataStore?.set(keyValue.value, forKey: keyValue.key)
        let event = HealthServiceData(healthType: type, recordedDate: date)
        self.collectionProtocol?.sendEvents(events: [event])
    }
    
    private func sendEvent(forType type: HealthType, date: Date = Date(), keyValue: HealthKeyValue, inCollectionType collectionType: EventCollectionType) {
        self.dataStore?.set(keyValue.value, forKey: keyValue.key)
        let event = HealthServiceData(healthType: type, recordedDate: date)
        self.collectionProtocol?.sendEvents(events: [event], eventCollectedIn: collectionType)
    }
    
    // MARK: Abstract Service Methods
    weak var collectionProtocol: AbstractCollectionPipeline?
    
    weak var eventBus: AbstractEventBus?
    
    func startService() throws -> ServiceError? {
        sendAppLauncedEvent()
        addObservers()
        sendBatteryEvents()
        //sendDeviceSwithOnEvent()
        return nil
    }
    
    func stopService() {
        if appState?.isPausedByUser == true {
            removeObservers()
        }
    }
    
    func isServiceRunning() -> Bool {
        return true
    }
    
    func isAuthorized() -> Bool {
        return true
    }
}
