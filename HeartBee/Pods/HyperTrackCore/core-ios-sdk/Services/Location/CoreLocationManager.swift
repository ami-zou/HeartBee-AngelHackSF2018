//
//  CoreLocationManager.swift
//  HyperTrackCore
//
//  Created by Atul Manwar on 18/06/18.
//  Copyright © 2018 www.hypertrack.com. All rights reserved.
//

import Foundation
import CoreLocation

//Class needs to be a subclass of NSObject to use CLLocationManagerDelegate
public final class CoreLocationManager: NSObject, AbstractLocationManager {
    fileprivate let locationManager: CLLocationManager
    fileprivate weak var config: AbstractLocationConfig?
    fileprivate weak var logger: AbstractLogger?
    fileprivate weak var eventBus: AbstractEventBus?
    public weak var updatesDelegate: LocationUpdateDelegate?
    public var isServiceRunning: Bool = false
    
    public var isAuthorized: Bool {
        switch CLLocationManager.authorizationStatus() {
        case .authorizedAlways:
            fallthrough
        case .authorizedWhenInUse:
            return true
        case .denied:
            fallthrough
        case .restricted:
            fallthrough
        case .notDetermined:
            return false
        }
    }
    
    var permissionCallback: BooleanCompletionHandler?
    
    public init(config: AbstractLocationConfig?, logger: AbstractLogger?, eventBus: AbstractEventBus?) {
        locationManager = CLLocationManager()
        self.logger = logger
        self.config = config
        self.eventBus = eventBus
        super.init()
        updateConfig(config)
    }
    
    public func updateConfig(_ config: AbstractLocationConfig?) {
        guard let config = config else { return }
        locationManager.allowsBackgroundLocationUpdates = config.location.backgroundLocationUpdates
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.pausesLocationUpdatesAutomatically = config.location.pausesLocationUpdatesAutomatically
        locationManager.activityType = CLActivityType.automotiveNavigation
        locationManager.distanceFilter = config.location.distanceFilter
        handleDeferredLocationUpdates()
        locationManager.delegate = self
        if #available(iOS 11.0, *) {
            locationManager.showsBackgroundLocationIndicator = config.location.showsBackgroundLocationIndicator
        }
    }
    
    public func startService() throws {
        guard let config = config else {
            logger?.logDebug("Location service not started because config was nil", context: Constant.Context.location)
            return
        }
        if isAuthorized {
            if config.location.onlySignificantLocationUpdates {
                locationManager.startMonitoringSignificantLocationChanges()
            } else {
                locationManager.startMonitoringSignificantLocationChanges()
                locationManager.startUpdatingLocation()
            }
            isServiceRunning = true
        } else {
            try? stopService()
            isServiceRunning = false
            throw CoreError(.locationPermissionsDenied)
        }
    }
    
    public func stopService() throws {
        guard let config = config else {
            logger?.logDebug("Location service not stopped because config was nil", context: Constant.Context.location)
            return
        }
        if config.location.onlySignificantLocationUpdates {
            locationManager.stopMonitoringSignificantLocationChanges()
        } else {
            locationManager.stopMonitoringSignificantLocationChanges()
            locationManager.stopUpdatingLocation()
        }
        isServiceRunning = false
    }
    
    public func requestPermissions(_ completionHandler: @escaping (Bool) -> Void) {
        permissionCallback = completionHandler
        let status = CLLocationManager.authorizationStatus()
        if locationServicesAlreadyRequested(status: status) {
            locationManager(locationManager, didChangeAuthorization: status)
        } else {
            guard let type = config?.location.permissionType else { return }
            switch type {
            case .always:
                locationManager.requestAlwaysAuthorization()
            default:
                locationManager.requestWhenInUseAuthorization()
            }
        }
    }
    
    public func handleActivityChange(_ type: ActivityServiceData.ActivityType) {
        switch type {
        case .stop:
            guard let location = locationManager.location else { return }
            locationManager(locationManager, didUpdateLocations: [location])
            locationManager.distanceFilter = Constant.Config.Location.distanceFilterForLowSpeed
        case .walk, .run:
            locationManager.distanceFilter = Constant.Config.Location.distanceFilterForLowSpeed
        default:
            locationManager.distanceFilter = Constant.Config.Location.distanceFilter
        }
    }
    
    fileprivate func handleDeferredLocationUpdates() {
        if let timeout = config?.location.deferredLocationUpdatesTimeout, let distance = config?.location.deferredLocationUpdatesDistance, timeout > 0, distance > 0 {
            locationManager.distanceFilter = kCLDistanceFilterNone
            locationManager.allowDeferredLocationUpdates(untilTraveled: distance, timeout: timeout)
        } else {
//            locationManager.disallowDeferredLocationUpdates()
//            locationManager.distanceFilter = config?.location.distanceFilter ?? Constant.Config.Location.distanceFilter
        }
    }
    
    fileprivate func locationServicesAlreadyRequested(status: CLAuthorizationStatus) -> Bool {
        switch status {
        case .authorizedAlways:
            fallthrough
        case .authorizedWhenInUse:
            fallthrough
        case .denied:
            fallthrough
        case .restricted:
            return true
        case .notDetermined:
            return false
        }
    }
    
    fileprivate func authStatusToAccessLevel(_ status: CLAuthorizationStatus) -> PrivateDataAccessLevel {
        switch status {
        case .authorizedAlways:
            return .grantedAlways
        case .authorizedWhenInUse:
            return .grantedWhenInUse
        case .denied:
            return .denied
        case .restricted:
            return .restricted
        case .notDetermined:
            return .undetermined
        }
    }
}

extension CoreLocationManager: CLLocationManagerDelegate {
    public func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        if isAuthorized {
            permissionCallback?(true)
        } else {
            permissionCallback?(false)
        }
        permissionCallback = nil
        /*
         * status always returns denied, when service is off
         */
        var updatedStatus: CLAuthorizationStatus = status
        if CLLocationManager.locationServicesEnabled() == false {
            updatedStatus = .restricted
        }
        eventBus?.post(name: Constant.Notification.Location.PermissionChangedEvent.name, userInfo: [Constant.Notification.Location.PermissionChangedEvent.key : authStatusToAccessLevel(updatedStatus)])
    }
    
    public func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        updatesDelegate?.locationUpdates(locations)
        handleDeferredLocationUpdates()
    }
    
    public func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        logger?.logError(error.localizedDescription, context: Constant.Context.location)
    }
}
