//
//  HyperTrackCore.swift
//  core-ios-sdk
//
//  Created by Atul Manwar on 06/06/18.
//  Copyright © 2018 www.hypertrack.com. All rights reserved.
//

import Foundation
import CoreLocation

public typealias BooleanCompletionHandler = (Bool) -> Void

public typealias ErrorCompletionHandler = (CoreError?) -> Void

@objc public enum ServiceStatus: Int {
    case started
    case stopped
    
    init(_ started: Bool) {
        if started {
            self = .started
        } else {
            self = .stopped
        }
    }
}

@objc(HTCoreServiceStatusUpdateDelegate) public protocol ServiceStatusUpdateDelegate: class {
    func serviceStatusUpdated(_ serviceType: Config.Services.ServiceType, status: ServiceStatus)
}

@objc(HTCoreServiceLocationUpdateDelegate) public protocol LocationUpdateDelegate: class {
    func locationUpdates(_ locations: [CLLocation])
}

/// This the entry point for the HyperTrack SDK.
/// Initialize and manage the lifecycle of the SDK.
@objc(HTCore) public final class HyperTrackCore: NSObject {
    /// Initialize the HyperTrack SDK by calling this method once from `didFinishLaunchingWithOptions` method in the `AppDelegate` class of your Application.
    /// - parameter publishableKey: A unique String that is used to identify your account with HyperTrack.
    /// - parameter completionHandler: A callback which takes an optional `CoreError` as a parameter and returns Void.
    ///   Use this handler to determine if there were any issues while initializing the SDK.
    @objc public class func initialize(publishableKey: String, completionHandler: @escaping (CoreError?) -> Void) {
        HyperTrackCore.initialize(publishableKey: publishableKey, config: Provider.configManager.config, completionHandler: completionHandler)
    }

    /// Initialize the HyperTrack SDK by calling this method once from `didFinishLaunchingWithOptions` method in the `AppDelegate` class of your Application.
    /// - parameter publishableKey: A unique String that is used to identify your account with HyperTrack.
    /// - parameter config: An optional `Config` instance which helps in tuning the SDK as per your requirement.
    ///   In case this parameter is not provided, a default configuration will used.
    /// - parameter completionHandler: A callback which takes an optional `CoreError` as a parameter and returns Void.
    ///   Use this handler to determine if there were any issues while initializing the SDK.
    @objc public class func initialize(publishableKey: String, config: Config, completionHandler: @escaping (CoreError?) -> Void) {
        Provider.logger.logDebug("SDK initialized", context: Constant.Context.lifecycle)
        Provider.appState.setPublishableKey(publishableKey)
        Provider.configManager.updateConfig(config)
        Provider.initPipeline.execute(completionHandler: completionHandler)
    }

    /// Initialize the HyperTrack SDK by calling this method once from `didFinishLaunchingWithOptions` method in the `AppDelegate` class of your Application.
    /// - parameter publishableKey: A unique String that is used to identify your account with HyperTrack.
    /// - parameter filePath: Path to a JSON or PropertyList file which provides a serialized `Config` data.
    ///   Please refer our sample app which has a template for the config file.
    /// - parameter completionHandler: A callback which takes an optional `CoreError` as a parameter and returns Void.
    ///   Use this handler to determine if there were any issues while initializing the SDK.
    @objc public class func initialize(publishableKey: String, filePath: String, completionHandler: @escaping (CoreError?) -> Void) {
        Provider.configManager.updateConfig(filePath: filePath)
        HyperTrackCore.initialize(publishableKey: publishableKey, config: Provider.configManager.config, completionHandler: completionHandler)
    }

    /// Returns a Bool indicating the location authorization status of your application.
    @objc public class func checkLocationPermission() -> Bool {
        Provider.logger.logDebug("check location permissions", context: Constant.Context.lifecycle)
        return Provider.serviceManager.isServiceAuthorized(Config.Services.ServiceType.location)
    }
    
    /// Request location permissions from the user.
    /// - parameter completionHandler: A callback which takes an optional `CoreError` as a parameter and returns Void.
    ///   Use this handler to determine whether the user has provided the required location permissions or not.
    @objc public class func requestLocationPermission(completionHandler: ((CoreError?) -> Void)?) {
        Provider.logger.logDebug("request location permissions", context: Constant.Context.lifecycle)
        Provider.initPipeline.getLocationServiceInitializationPipeline().execute { (error) in
            Provider.initPipeline.execute(completionHandler: nil)
            completionHandler?(error)
        }
    }
    
    /// Returns a Bool indicating the motion authorization status of your application.
    @objc public class func checkActivityPermission() -> Bool {
        Provider.logger.logDebug("check activity permissions", context: Constant.Context.lifecycle)
        return Provider.serviceManager.isServiceAuthorized(Config.Services.ServiceType.activity)
    }
    
    /// Request motion permissions from the user.
    /// - parameter completionHandler: A callback which takes an optional `CoreError` as a parameter and returns Void.
    ///   Use this handler to determine whether the user has provided the required motion permissions or not.
    @objc public class func requestActivityPermission(completionHandler: ((CoreError?) -> Void)?) {
        Provider.logger.logDebug("request activity permissions", context: Constant.Context.lifecycle)
        Provider.initPipeline.getActivityServiceInitializationPipeline().execute { (error) in
            Provider.initPipeline.execute(completionHandler: nil)
            completionHandler?(error)
        }
    }
    
    /// Allows the SDK to resume a previously paused tracking.
    /// Call this method when you had previously made a call to `pauseTracking()` method.
    /// While setting up the SDK you don't need to explicitly call this method.
    /// The SDK will automatically start recording data as soon as it receives the required permissions.
    @objc public class func resumeTracking() {
        Provider.logger.logDebug("resume tracking", context: Constant.Context.lifecycle)
        Provider.appState.isPausedByUser = false
        Provider.serviceManager.startAllServices()
        Provider.eventBus.post(name: Constant.Notification.Tracking.Resume.name, userInfo: nil)
    }
    
    /// Allows the SDK to resume a previously paused tracking.
    /// Call this method when you had previously made a call to `pauseTracking()` method.
    /// While setting up the SDK you don't need to explicitly call this method.
    /// The SDK will automatically start recording data as soon as it receives the required permissions.
    /// If sdk initialization steps are not completed, it will throw the error.
    @objc public class func resumeTracking(completionHandler: ErrorCompletionHandler?) {
        // app initializtion is done
        let appState = Provider.appState
        if appState.isAppInitialized == false {
            completionHandler?(CoreError.init(ErrorType.sdkNotInitialized))
            return
        }
        // check location permission
        if self.checkLocationPermission() == false {
            //TODO: Both cases handling, permission denied and permission not asked
            completionHandler?(CoreError.init(ErrorType.locationPermissionsDenied))
            return
        }
        if self.checkActivityPermission() == false {
            //TODO: Both cases handling, permission denied and permission not asked
            completionHandler?(CoreError.init(ErrorType.activityPermissionsDenied))
            return
        }
        // All good
        Provider.appState.isPausedByUser = false
        Provider.serviceManager.startAllServices()
        Provider.eventBus.post(name: Constant.Notification.Tracking.Resume.name, userInfo: nil)
        completionHandler?(nil)
    }
    
    /// Stops the SDK from listening to user's movement updates and recording any data.
    /// If this method is called, the SDK will not resume movement tracking until `resumeTracking()` method is called.
    @objc public class func pauseTracking() {
        Provider.logger.logDebug("pause tracking", context: Constant.Context.lifecycle)
        Provider.appState.isPausedByUser = true
        Provider.serviceManager.stopAllServices()
        Provider.eventBus.post(name: Constant.Notification.Tracking.Pause.name, userInfo: nil)
    }
    
    /// Returns a string which is used by HyperTrack to uniquely identify the user.
    /// - returns: A unique identifier.
    @objc public class func getDeviceId() -> String {
        Provider.logger.logDebug("get device id", context: Constant.Context.lifecycle)
        return Provider.appState.getDeviceId()
    }
    
    /// This method is for internal use only.
    /// Please do not use this method as it might hamper the data collected by SDK.
    @objc public class func setDeviceId(_ id: String) {
        Provider.logger.logDebug("set device id", context: Constant.Context.lifecycle)
        Provider.appState.setDeviceId(id)
    }
    
    /// Determine whether the SDK is tracking the movement of the user.
    /// - returns: Whether user's movement data is getting tracked or not.
    @objc public class var isTracking: Bool {
        Provider.logger.logDebug("is tracking", context: Constant.Context.lifecycle)
        return Provider.serviceManager.numberOfRunningServices() > 0
    }
    
    /// Determine whether the SDK is tracking the location of the user.
    /// - returns: Whether user's location data is getting tracked or not.
    @objc public class func isLocationServiceRunning() -> Bool {
        Provider.logger.logDebug("is location service running", context: Constant.Context.lifecycle)
        return Provider.serviceManager.isServiceRunning(Config.Services.ServiceType.location)
    }
    
    /// Determine whether the SDK is tracking the activities of the user.
    /// - returns: Whether user's motion data is getting tracked or not.
    @objc public class func isActivityServiceRunning() -> Bool {
        Provider.logger.logDebug("is activity service running", context: Constant.Context.lifecycle)
        return Provider.serviceManager.isServiceRunning(Config.Services.ServiceType.activity)
    }
    
    /// This method is for internal use only.
    /// Please do not use this method as it might hamper the data collected by SDK.
    @objc public class func setServiceStatusUpdatesDelegate(_ delegate: ServiceStatusUpdateDelegate) {
        Provider.logger.logDebug("set service status updates delegate", context: Constant.Context.lifecycle)
        Provider.serviceManager.statusUpdatesDelegate = delegate
    }
    
    /// This method is for internal use only.
    /// Please do not use this method as it might hamper the data collected by SDK.
    @objc public class func setEventUpdatesDelegate( _ delegate: EventUpdatesDelegate?, serviceType: Config.Services.ServiceType) {
        Provider.logger.logDebug("set event updates delegate", context: Constant.Context.lifecycle)
        Provider.serviceManager.setEventUpdatesDelegate(delegate, serviceType: serviceType)
    }
    
    /// Ask the SDK to transmit the movement data saved by the SDK.
    /// Usually this is not required as the SDK efficiently determines when to transmit the data.
    @objc public class func dispathEventsNow() {
        Provider.logger.logDebug("dispatch events now", context: Constant.Context.lifecycle)
        Provider.dispatch.dispatch()
    }
    
    /// Register for callbacks to location updates
    /// - parameter delegate: A delegate which implements `LocationUpdateDelegate`. The SDK will call `locationUpdates(...)` when new locations are received from the `CLLocationManager`.
    @objc public class func setLocationUpdatesDelegate(_ delegate: LocationUpdateDelegate?) {
        Provider.logger.logDebug("set location updates delegate", context: Constant.Context.lifecycle)
        Provider.serviceManager.setLocationUpdatesDelegate(delegate)
    }
}
