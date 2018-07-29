//
//  ActivityService.swift
//  core-ios-sdk
//
//  Created by Ashish Asawa on 04/06/18.
//  Copyright © 2018 www.hypertrack.com. All rights reserved.
//

import Foundation
import CoreMotion

@objc(HTCoreEventUpdatesDelegate) public protocol EventUpdatesDelegate: class {
    func didChangeEvent(_ dict: Payload, serviceType: Config.Services.ServiceType)
}

final class ActivityService: AbstractService  {
    private let activityManager         = CMMotionActivityManager()
    private let pedometer               = CMPedometer()
    private let activityQueueName       = "HTActivityQueue"
    private let promptKey               = "HTCoreMotionPermissionMotionPromptKey"
    private let receivedKey             = "HTCoreMotionPermissionMotionReceivedKey"
    private let lastActivityTypeKey     = "HTCoreMotionLastActivityTypeKey"
    private var isRunning               = false
    private var lastActivityType        = ActivityServiceData.ActivityType.stop //TODO: Optional
    
    weak private var dataStore: AbstractReadWriteDataStore?
    
    fileprivate weak var delegate: EventUpdatesDelegate?
    
    private lazy var activityQueue: OperationQueue = {
        var queue = OperationQueue()
        queue.name = self.activityQueueName
        queue.maxConcurrentOperationCount = 1
        return queue
    }()
    
    init(withCollectionProtocol collectionProtocol: AbstractCollectionPipeline?, eventBus: AbstractEventBus?, dataStore: AbstractReadWriteDataStore?) {
        self.collectionProtocol = collectionProtocol
        self.eventBus           = eventBus
        self.dataStore          = dataStore
        self.eventBus?.addObserver(self, selector: #selector(ActivityService.appWillComeToForeground), name: NSNotification.Name.UIApplicationWillEnterForeground.rawValue)
        if let savedType = dataStore?.string(forKey: lastActivityTypeKey), let inferredType = ActivityServiceData.ActivityType(rawValue: savedType) {
            lastActivityType = inferredType
        }
        self.eventBus?.addObserver(self, selector: #selector(self.heartbeatStatusChanged(_:)), name: Constant.Notification.HeartbeatService.StatusChangedEvent.name)
    }
    
    // MARK: Abstract Service Methods
    
    weak var collectionProtocol: AbstractCollectionPipeline?
    
    weak var eventBus: AbstractEventBus?
    
    func startService() throws -> ServiceError? {
        checkPermissionStatus()
        if isAuthorized() {
            guard !isRunning else { return nil }
            isRunning = true
            activityManager.startActivityUpdates(to: activityQueue) { [weak self] (activity) in
                if let activity = activity {
                    self?.handleActivityReceived(activity: activity)
                }
            }
            return nil
        } else {
            if accessLevel != .undetermined {
                stopService()
            }
            switch accessLevel {
            case .undetermined:
                throw ServiceError.permissionNotTaken
            case .unavailable:
                throw ServiceError.hardwareNotSupported
            case .denied, .restricted:
                throw ServiceError.userDenied
            default:
                return nil
            }
        }
    }
    
    func stopService() {
        guard isAuthorized() else { return }
        self.activityManager.stopActivityUpdates()
        isRunning = false
    }
    
    func isServiceRunning() -> Bool {
        return self.isRunning
    }
    
    func isAuthorized() -> Bool {
        switch accessLevel {
        case .granted:
            fallthrough
        case .grantedAlways:
            fallthrough
        case .grantedWhenInUse:
            return true
        default:
            return false
        }
    }
    
    private func handleActivityReceived(activity: CMMotionActivity) {
        let event = ActivityServiceData(activityId: UUID().uuidString, osActivity: activity, recordedDate: activity.startDate)
        if activity.confidence == .high && lastActivityType.rawValue != event.data.value, let type = event.data.type, type.isSupported {
            collectionProtocol?.sendEvents(events: [event])
            lastActivityType = type
            dataStore?.set(event.data.value, forKey: lastActivityTypeKey)
            eventBus?.post(name: Constant.Notification.Activity.ActivityChangedEvent.name, userInfo: [Constant.Notification.Activity.ActivityChangedEvent.key: type])
        }
        delegate?.didChangeEvent(["sensor_data": activity, "inferred": event.data.value], serviceType: .activity)
    }
    
    // MARK: Heartbeat Service Notification
    @objc func heartbeatStatusChanged(_ notif: Notification) {
        guard let status = notif.userInfo?[Constant.Notification.HeartbeatService.StatusChangedEvent.key] as? HeartbeatService.Status else {
            return
        }
        if status == .reconnect {
            // Sending previously saved event again to our server, to handle the timeline correctly
            if let savedType = dataStore?.string(forKey: lastActivityTypeKey), let inferredType = ActivityServiceData.ActivityType(rawValue: savedType) {
                let event = ActivityServiceData.createActivity(fromType: inferredType)
                collectionProtocol?.sendEvents(events: [event])
            }
        }
    }
    
    // MARK: Background/ Foreground Methods
    @objc func appWillComeToForeground() {
        checkPermissionStatus()
    }
    
    func setEventUpdatesDelegate(_ delegate: EventUpdatesDelegate?) {
        self.delegate = delegate
    }
    
    private func checkPermissionStatus() {
        let status = self.accessLevel
        if status != .undetermined {
            // propmt has been made before
            self.requestAccess { [weak self] (result) in
                if result.accessLevel != status {
                    self?.eventBus?.post(name: Constant.Notification.Activity.PermissionChangedEvent.name, userInfo: [Constant.Notification.Activity.PermissionChangedEvent.key: result.accessLevel])
                }
            }
        }
    }
}

extension ActivityService: PrivateDataAccessProvider {
    
    var accessLevel: PrivateDataAccessLevel {
        var status: PrivateDataAccessLevel = .undetermined
        if CMMotionActivityManager.isActivityAvailable() == false {
            // hardware level not available
            status = .unavailable
        } else {
            if dataStore?.string(forKey: promptKey) == nil {
                status = .undetermined
            } else {
                // Prompt has been presented in the past
                if dataStore?.string(forKey: receivedKey) == nil {
                    status = .denied
                } else {
                    status = .granted
                }
            }
        }
        return status
    }
    
    
    func requestAccess(completionHandler: @escaping (PrivateDataRequestAccessResult) -> Void) {
        if CMMotionActivityManager.isActivityAvailable() == true {
            dataStore?.set("1", forKey: promptKey)
            activityManager.queryActivityStarting(from: Date(), to: Date(), to: activityQueue) {[weak self] activities, error in
                if let _ = activities {
                    self?.dataStore?.set("1", forKey: self?.receivedKey ?? "")
                    completionHandler(PrivateDataRequestAccessResult.init(PrivateDataAccessLevel.granted))
                }
                else if let error = error {
                    self?.dataStore?.removeObject(forKey: self?.receivedKey ?? "")
                    self?.handleError(error as NSError, completionHandler: completionHandler)
                }
            }
        } else {
            // hardware level not supported
            dataStore?.removeObject(forKey: receivedKey)
            completionHandler(PrivateDataRequestAccessResult.init(PrivateDataAccessLevel.unavailable))
        }
    }
    
    private func handleError(_ error: NSError, completionHandler: @escaping (PrivateDataRequestAccessResult) -> Void) {
        if error.code == Int(CMErrorMotionActivityNotAuthorized.rawValue) {
            completionHandler(PrivateDataRequestAccessResult.init(.denied, error: error))
        } else {
            completionHandler(PrivateDataRequestAccessResult.init(.restricted, error: error))
        }
    }
    
}
