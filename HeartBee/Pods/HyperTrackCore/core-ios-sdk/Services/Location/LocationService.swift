//
//  LocationService.swift
//  core-ios-sdk
//
//  Created by Atul Manwar on 07/06/18.
//  Copyright © 2018 www.hypertrack.com. All rights reserved.
//

import Foundation
import CoreLocation


protocol AbstractLocationService: AbstractService, AbstractLocationUpdate {
    func requestPermissions(_ completionHandler: @escaping (Bool) -> Void)
}

public protocol AbstractLocationManager {
    var isServiceRunning: Bool { get }
    var isAuthorized: Bool { get }
    var updatesDelegate: LocationUpdateDelegate? { get set }
    func startService() throws
    func stopService() throws
    func updateConfig(_ config: AbstractLocationConfig?)
    func requestPermissions(_ completionHandler: @escaping (Bool) -> Void)
    func handleActivityChange(_ type: ActivityServiceData.ActivityType)
}

public final class LocationService: AbstractLocationService, LocationUpdateDelegate {
    
    fileprivate var locationManager: AbstractLocationManager
    fileprivate weak var config: AbstractLocationConfig?
    fileprivate weak var logger: AbstractLogger?
    fileprivate weak var appState: AbstractAppState?
    
    public weak var collectionProtocol: AbstractCollectionPipeline?
    public weak var eventBus: AbstractEventBus?
    fileprivate weak var locationUpdatesDelegate: LocationUpdateDelegate?
    
    public init(config: AbstractLocationConfig?, logger: AbstractLogger?, locationManager: AbstractLocationManager, collection: AbstractCollectionPipeline?, eventBus: AbstractEventBus?, appState: AbstractAppState?) {
        self.logger = logger
        self.config = config
        self.appState = appState
        self.locationManager = locationManager
        collectionProtocol = collection
        self.eventBus = eventBus
        self.locationManager.updatesDelegate = self
        self.eventBus?.addObserver(self, selector: #selector(updateConfig(_ :)), name: Constant.Notification.Config.ConfigChangedEvent.name)
        self.eventBus?.addObserver(self, selector: #selector(handleActivityChange(_ :)), name: Constant.Notification.Activity.ActivityChangedEvent.name)
    }
    
    public func startService() throws -> ServiceError? {
        do {
            try locationManager.startService()
        } catch let error {
            throw error
        }
        return nil
    }
    
    public func stopService() {
        do {
            try locationManager.stopService()
        } catch {
            
        }
    }
    
    public func isServiceRunning() -> Bool {
        return locationManager.isServiceRunning
    }
    
    @objc func updateConfig(_ notification: Notification) {
        locationManager.updateConfig(config)
    }

    @objc func handleActivityChange(_ notification: Notification) {
        guard let type = notification.userInfo?[Constant.Notification.Activity.ActivityChangedEvent.key] as? ActivityServiceData.ActivityType else { return }
        locationManager.handleActivityChange(type)
    }

    func mapLocationsToLocationServiceData(_ locations: [CLLocation]) -> [LocationServiceData] {
        guard let locations = Array(NSOrderedSet(array: locations)) as? [CLLocation] else { return [] }
        return LocationServiceData.getData(locations)
    }
    
    public func locationUpdates(_ locations: [CLLocation]) {
        collectionProtocol?.sendEvents(events: mapLocationsToLocationServiceData(locations)) //TODO: remove direct access to CoreSDKProvider
        self.locationUpdatesDelegate?.locationUpdates(locations)
    }

    public func requestPermissions(_ completionHandler: @escaping (Bool) -> Void) {
        locationManager.requestPermissions(completionHandler)
    }
    
    public func isAuthorized() -> Bool {
        return locationManager.isAuthorized
    }
    
    public func setLocationUpdatesDelegate(_ delegate: LocationUpdateDelegate?) {
        self.locationUpdatesDelegate = delegate
    }
    
}
