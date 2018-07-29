//
//  ServiceManager.swift
//  core-ios-sdk
//
//  Created by Atul Manwar on 12/06/18.
//  Copyright © 2018 www.hypertrack.com. All rights reserved.
//

import Foundation

public protocol BaseServiceManager: class {
    func startAllServices()
    func stopAllServices()
}

public protocol AbstractServiceManager: AbstractServiceProtocol, AbstractLocationUpdate, BaseServiceManager {
    
}

public protocol AbstractServiceProtocol: class {
    var statusUpdatesDelegate: ServiceStatusUpdateDelegate? { get set }
    func getService(_ serviceType: Config.Services.ServiceType) -> AbstractService?
    func startService(_ serviceType: Config.Services.ServiceType) throws -> ServiceError?
    func stopService(_ serviceType: Config.Services.ServiceType)
    func isServiceAuthorized(_ serviceType: Config.Services.ServiceType) -> Bool
    func isServiceRunning(_ serviceType: Config.Services.ServiceType) -> Bool
    func setEventUpdatesDelegate(_ delegate: EventUpdatesDelegate?, serviceType: Config.Services.ServiceType)
    func numberOfServices() -> Int
    func numberOfRunningServices() -> Int
}

public protocol AbstractLocationUpdate: class {
    func setLocationUpdatesDelegate(_ delegate: LocationUpdateDelegate?)
}

public final class ServiceManager: AbstractServiceManager, AbstractLocationUpdate {

    fileprivate var services: [Config.Services.ServiceType: AbstractService] = [:]
    fileprivate weak var logger: AbstractLogger?
    fileprivate weak var eventBus: AbstractEventBus?
    fileprivate weak var appState: AbstractAppState?
    fileprivate var canStartServices: Bool {
        return (appState?.isPausedByUser == false && appState?.isAppInitialized == true)
    }
    weak public var statusUpdatesDelegate: ServiceStatusUpdateDelegate? {
        didSet {
            services.forEach({
                serviceStatusUpdated($0.key, status: ServiceStatus($0.value.isServiceRunning()))
            })
        }
    }
    
    init(serviceTypes: [Config.Services.ServiceType], config: AbstractConfig?, logger: AbstractLogger?, eventBus: AbstractEventBus?, appState: AbstractAppState?, collection: AbstractCollectionPipeline?, factory: AbstractServiceFactory) {
        self.logger = logger
        self.eventBus = eventBus
        self.appState = appState
        serviceTypes.forEach({
            self.services[$0] = factory.getService($0, config: config, collection: collection)
        })
        self.eventBus?.addObserver(self, selector: #selector(locationPermissionChanged(_:)), name: Constant.Notification.Location.PermissionChangedEvent.name)
        self.eventBus?.addObserver(self, selector: #selector(activityPermissionChanged(_:)), name: Constant.Notification.Activity.PermissionChangedEvent.name)
    }

    @objc func activityPermissionChanged(_ notification: Notification) {
        guard let accessLevel = notification.userInfo?[Constant.Notification.Activity.PermissionChangedEvent.key] as? PrivateDataAccessLevel else { return }
        handlePermissionChanged(accessLevel, serviceType: .activity)
    }

    @objc func locationPermissionChanged(_ notification: Notification) {
        guard let accessLevel = notification.userInfo?[Constant.Notification.Location.PermissionChangedEvent.key] as? PrivateDataAccessLevel else { return }
        handlePermissionChanged(accessLevel, serviceType: .location)
    }

    fileprivate func handlePermissionChanged(_ accessLevel: PrivateDataAccessLevel, serviceType: Config.Services.ServiceType) {
        switch accessLevel {
        case .granted, .grantedAlways, .grantedWhenInUse:
            logger?.logDebug("Permission granted \(serviceType.description)", context: Constant.Context.services)
            startAllServices()
        case .denied, .restricted, .unavailable, .undetermined:
            logger?.logDebug("Permission denied \(serviceType.description)", context: Constant.Context.services)
            stopAllServices()
        }
    }
    
    public func numberOfServices() -> Int {
        return services.count
    }
    
    public func numberOfRunningServices() -> Int {
        return services.filter({ $0.value.isServiceRunning() }).count
    }
    
    public func getService(_ serviceType: Config.Services.ServiceType) -> AbstractService? {
        return services[serviceType]
    }
    
    public func startService(_ serviceType: Config.Services.ServiceType) throws -> ServiceError? {
        guard canStartServices else { return nil }
        do {
            _ = try services[serviceType]?.startService()
            serviceStatusUpdated(serviceType, status: .started)
            logger?.logDebug("Started \(serviceType.description)", context: Constant.Context.services)
            return nil
        } catch let error {
            serviceStatusUpdated(serviceType, status: .stopped)
            logger?.logError("Unable to start \(serviceType.description)", context: Constant.Context.services)
            throw error
        }
    }
    
    public func stopService(_ serviceType: Config.Services.ServiceType) {
        services[serviceType]?.stopService()
        serviceStatusUpdated(serviceType, status: .stopped)
    }
    
    fileprivate func serviceStatusUpdated(_ serviceType: Config.Services.ServiceType, status: ServiceStatus) {
        DispatchQueue.main.async { [weak self] in
            self?.statusUpdatesDelegate?.serviceStatusUpdated(serviceType, status: status)
        }
    }
    
    public func startAllServices() {
        guard services.filter({ !$0.value.isAuthorized() }).count == 0 else { return }
        services.forEach({
            do {
                _ = try startService($0.key)
            } catch  {
                
            }
        })
    }
    
    public func stopAllServices() {
        services.forEach({
            stopService($0.key)
        })
    }
    
    public func isServiceAuthorized(_ serviceType: Config.Services.ServiceType) -> Bool {
        return services[serviceType]?.isAuthorized() ?? false
    }
    
    public func isServiceRunning(_ serviceType: Config.Services.ServiceType) -> Bool {
        return services[serviceType]?.isServiceRunning() ?? false
    }
    
    public func setEventUpdatesDelegate(_ delegate: EventUpdatesDelegate?, serviceType: Config.Services.ServiceType) {
        services[serviceType]?.setEventUpdatesDelegate(delegate)
    }
    
    //MARK: Location Updates Delegate Method
    public func setLocationUpdatesDelegate(_ delegate: LocationUpdateDelegate?) {
        if let locationService = services[Config.Services.ServiceType.location] as? AbstractLocationUpdate {
            locationService.setLocationUpdatesDelegate(delegate)
        }
    }
}

//@objc(HTCoreAbstractServiceFactory)
public protocol AbstractServiceFactory {
    func getService(_ type: Config.Services.ServiceType, config: AbstractConfig?, collection: AbstractCollectionPipeline?) -> AbstractService
}

final class ServiceFactory: AbstractServiceFactory {
    func getService(_ type: Config.Services.ServiceType, config: AbstractConfig?, collection: AbstractCollectionPipeline?) -> AbstractService {
        switch type {
        case .location:
            return LocationService(config: config, logger: Provider.logger, locationManager: CoreLocationManager(config: config, logger: Provider.logger, eventBus: Provider.eventBus), collection: collection, eventBus: Provider.eventBus, appState: Provider.appState)
        case .activity:
            return ActivityService(withCollectionProtocol: collection, eventBus: Provider.eventBus, dataStore: Provider.dataStore)
        case .health:
            return HealthService(withCollectionProtocol: collection, eventBus: Provider.eventBus, dataStore: Provider.dataStore, appState: Provider.appState)
        }
    }
}
