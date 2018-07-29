//
//  ConfigManager.swift
//  core-ios-sdk
//
//  Created by Atul Manwar on 01/06/18.
//  Copyright © 2018 www.hypertrack.com. All rights reserved.
//

import Foundation

public protocol AbstractNetworkConfig: class {
    var network: Config.Network { get }
}

public protocol AbstractDataStoreConfig: class {
    var dataStore: Config.DataStore { get }
}

public protocol AbstractDispatchConfig: class {
    var dispatch: Config.Dispatch { get }
}

public protocol AbstractTransmissionConfig: AbstractNetworkConfig {
    var transmission: Config.Transmission { get }
}

public protocol AbstractLocationConfig: class {
    var location: Config.Location { get }
}

public protocol AbstractCollectionConfig: class {
    var collection: Config.Collection { get }
}

public protocol AbstractActivityConfig: class {
    var activity: Config.Activity { get }
}

public protocol AbstractServicesConfig: class {
    var services: Config.Services { get }
}

public protocol HeartbeatServiceConfig: class {
    var heartbeat: Config.HeartbeatService { get }
}

public protocol AbstractConfig: AbstractDataStoreConfig,
    AbstractDispatchConfig,
    AbstractTransmissionConfig,
    AbstractLocationConfig,
    AbstractActivityConfig,
    AbstractServicesConfig,
    AbstractCollectionConfig,
    HeartbeatServiceConfig {
}

public protocol AbstractConfigManager {
    var config: Config { get }
    func updateConfig(_ config: Config)
    func updateConfig(filePath: String)
    func save()
}

public final class ConfigManager: AbstractConfigManager {
    public private(set) var config: Config
    fileprivate weak var storage: AbstractFileStorage?
    fileprivate weak var logger: AbstractLogger?
    var fileName: String {
        return "\(Constant.namespace)\(Config.self).json"
    }

    public init() {
        config = Config()
    }

    convenience init(storage: AbstractFileStorage?, logger: AbstractLogger?) {
        self.init()
        self.storage = storage
        self.logger = logger
        guard let storedValues = storage?.retrieve(fileName, from: .documents, as: Config.self) else {
            return
        }
        config = storedValues
    }

    public func save() {
        storage?.store(config, to: .documents, as: fileName)
    }
    
    public func updateConfig(_ config: Config) {
        self.config.update(config)
    }
    
    public func updateConfig(filePath: String) {
        guard let config = storage?.retrieve(filePath, as: Config.self) else {
            logger?.logError("Unable to parse data from file \(filePath)", context: Constant.Context.config)
            return
        }
        self.config.update(config)
        save()
    }

    deinit {
        save()
    }
}

@objc(HTCoreConfig) public final class Config: NSObject, AbstractConfig, Codable {
    public var network: Network
    public var dataStore: DataStore
    public var dispatch: Dispatch
    public var transmission: Transmission
    public var location: Location
    public var activity: Activity
    public var services: Services
    public var collection: Collection
    public var heartbeat: HeartbeatService

    public static var `default`: Config = Config()

    public override init() {
        network = Network()
        dataStore = DataStore()
        dispatch = Dispatch()
        transmission = Transmission()
        location = Location()
        activity = Activity()
        services = Services()
        collection = Config.Collection()
        heartbeat  = Config.HeartbeatService()
        super.init()
    }
    
    func update(_ config: Config) {
        self.network = config.network
        self.dataStore = config.dataStore
        self.dispatch = config.dispatch
        self.transmission = config.transmission
        self.location = config.location
        self.activity = config.activity
        self.services = config.services
        self.collection = config.collection
        self.heartbeat  = config.heartbeat
    }

    enum Keys: String, CodingKey {
        case network = "network"
        case dataStore = "data_store"
        case dispatch = "dispatch"
        case transmission = "transmission"
        case location = "location"
        case activity = "activity"
        case services = "services"
        case collection = "collection"
        case heartbeat = "heartbeat"
    }

    public required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: Keys.self)
        network = (try? container.decode(Network.self, forKey: .network)) ?? Network()
        dataStore = (try? container.decode(DataStore.self, forKey: .dataStore)) ?? DataStore()
        dispatch = (try? container.decode(Dispatch.self, forKey: .dispatch)) ?? Dispatch()
        transmission = (try? container.decode(Transmission.self, forKey: .transmission)) ?? Transmission()
        location = (try? container.decode(Location.self, forKey: .location)) ?? Location()
        activity = (try? container.decode(Activity.self, forKey: .activity)) ?? Activity()
        services = (try? container.decode(Services.self, forKey: .services)) ?? Services()
        collection = (try? container.decode(Collection.self, forKey: .collection)) ?? Collection()
        heartbeat = (try? container.decode(HeartbeatService.self, forKey: .heartbeat)) ?? HeartbeatService()
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: Keys.self)
        try container.encode(network, forKey: .network)
        try container.encode(dataStore, forKey: .dataStore)
        try container.encode(dispatch, forKey: .dispatch)
        try container.encode(transmission, forKey: .transmission)
        try container.encode(location, forKey: .location)
        try container.encode(activity, forKey: .activity)
        try container.encode(services, forKey: .services)
        try container.encode(collection, forKey: .collection)
        try container.encode(heartbeat, forKey: .heartbeat)
    }
}

extension Config {
    // MARK: - Internal classes
    public struct Network: Codable {
        public var timeoutInterval: Double
        public var retryCount: Int
        public var host: String

        public init() {
            timeoutInterval = Constant.Config.Network.timeoutInterval
            retryCount = Constant.Config.Network.retryCount
            host = Constant.Config.Network.host
        }

        enum Keys: String, CodingKey {
            case timeoutInterval = "timeout_interval"
            case retryCount = "retry_count"
            case host = "host"
        }

        public init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: Keys.self)
            timeoutInterval = (try? container.decode(Double.self, forKey: .timeoutInterval)) ?? Constant.Config.Network.timeoutInterval
            retryCount = (try? container.decode(Int.self, forKey: .retryCount)) ?? Constant.Config.Network.retryCount
            host = (try? container.decode(String.self, forKey: .host)) ?? Constant.Config.Network.host
        }

        public func encode(to encoder: Encoder) throws {
            var container = encoder.container(keyedBy: Keys.self)
            try container.encode(timeoutInterval, forKey: .timeoutInterval)
            try container.encode(retryCount, forKey: .retryCount)
            try container.encode(host, forKey: .host)
        }
    }
}

extension Config {
    public struct DataStore: Codable {
        public var dataStoreSuitName: String

        public init() {
            dataStoreSuitName = Constant.Config.DataStore.dataStoreSuitName
        }

        enum Keys: String, CodingKey {
            case dataStoreSuitName = "data_store_suit_name"
        }

        public init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: Keys.self)
            dataStoreSuitName = (try? container.decode(String.self, forKey: .dataStoreSuitName))
                ?? Constant.Config.DataStore.dataStoreSuitName
        }

        public func encode(to encoder: Encoder) throws {
            var container = encoder.container(keyedBy: Keys.self)
            try container.encode(dataStoreSuitName, forKey: .dataStoreSuitName)
        }
    }
}

extension Config {
    public struct Dispatch: Codable {
        public var frequency: Double
        public let debounce: Double
        public let throttle: Double
        public var tolerance: Int
        public var type: DispatchType

        public init() {
            frequency = Constant.Config.Dispatch.frequency
            tolerance = Constant.Config.Dispatch.tolerance
            debounce = Constant.Config.Dispatch.debounce
            throttle = Constant.Config.Dispatch.throttle
            type = .timer
        }

        public enum DispatchType: Int, Codable {
            case manual
            case timer
        }

        enum Keys: String, CodingKey {
            case frequency = "frequency"
            case tolerance = "tolerance"
            case debounce = "debounce"
            case throttle = "throttle"
            case type = "type"
        }

        public init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: Keys.self)
            frequency = (try? container.decode(Double.self, forKey: .frequency)) ?? Constant.Config.Dispatch.frequency
            tolerance = (try? container.decode(Int.self, forKey: .tolerance)) ?? Constant.Config.Dispatch.tolerance
            debounce = (try? container.decode(Double.self, forKey: .debounce)) ?? Constant.Config.Dispatch.debounce
            throttle = (try? container.decode(Double.self, forKey: .throttle)) ?? Constant.Config.Dispatch.throttle
            type = (try? container.decode(DispatchType.self, forKey: .type)) ?? .timer
        }
        
        public func encode(to encoder: Encoder) throws {
            var container = encoder.container(keyedBy: Keys.self)
            try container.encode(frequency, forKey: .frequency)
            try container.encode(tolerance, forKey: .tolerance)
            try container.encode(debounce, forKey: .debounce)
            try container.encode(throttle, forKey: .throttle)
            try container.encode(type, forKey: .type)
        }
    }
}

extension Config {
    public struct Transmission: Codable {
        public var batchSize: UInt

        public init() {
            batchSize = Constant.Config.Transmission.batchSize
        }

        enum Keys: String, CodingKey {
            case batchSize = "batch_size"
        }

        public init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: Keys.self)
            batchSize = (try? container.decode(UInt.self, forKey: .batchSize)) ?? Constant.Config.Transmission.batchSize
        }

        public func encode(to encoder: Encoder) throws {
            var container = encoder.container(keyedBy: Keys.self)
            try container.encode(batchSize, forKey: .batchSize)
        }
    }
}

extension Config {
    public struct Location: Codable {
        public var onlySignificantLocationUpdates: Bool
        public var deferredLocationUpdatesDistance: Double
        public var deferredLocationUpdatesTimeout: Double
        public var backgroundLocationUpdates: Bool
        public var distanceFilter: Double
        public var desiredAccuracy: Double
        public var permissionType: PermissionType
        public var showsBackgroundLocationIndicator: Bool
        public var pausesLocationUpdatesAutomatically: Bool

        public enum PermissionType: Int, Codable {
            case always
            case whenInUse
        }

        public init() {
            onlySignificantLocationUpdates = Constant.Config.Location.onlySignificantLocationUpdates
            deferredLocationUpdatesDistance = Constant.Config.Location.deferredLocationUpdatesDistance
            deferredLocationUpdatesTimeout = Constant.Config.Location.deferredLocationUpdatesTimeout
            backgroundLocationUpdates = Constant.Config.Location.backgroundLocationUpdates
            distanceFilter = Constant.Config.Location.distanceFilter
            desiredAccuracy = Constant.Config.Location.desiredAccuracy
            showsBackgroundLocationIndicator = Constant.Config.Location.showsBackgroundLocationIndicator
            permissionType = PermissionType(rawValue: Constant.Config.Location.permissionType) ?? .always
            pausesLocationUpdatesAutomatically = Constant.Config.Location.pausesLocationUpdatesAutomatically
        }

        enum Keys: String, CodingKey {
            case onlySignificantLocationUpdates = "only_significant_location_updates"
            case deferredLocationUpdatesDistance = "deferred_location_updates_distance"
            case deferredLocationUpdatesTimeout = "deferred_location_updates_timeout"
            case backgroundLocationUpdates = "background_location_updates"
            case distanceFilter = "distance_filter"
            case desiredAccuracy = "desired_accuracy"
            case permissionType = "permission_type"
            case showsBackgroundLocationIndicator = "shows_background_location_indicator"
            case pausesLocationUpdatesAutomatically = "pauses_location_updates_automatically"
        }

        public init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: Keys.self)
            onlySignificantLocationUpdates = (try? container.decode(Bool.self, forKey: .onlySignificantLocationUpdates)) ?? Constant.Config.Location.onlySignificantLocationUpdates
            deferredLocationUpdatesDistance = (try? container.decode(Double.self, forKey: .deferredLocationUpdatesDistance)) ?? Constant.Config.Location.deferredLocationUpdatesDistance
            deferredLocationUpdatesTimeout = (try? container.decode(Double.self, forKey: .deferredLocationUpdatesTimeout)) ?? Constant.Config.Location.deferredLocationUpdatesTimeout
            backgroundLocationUpdates = (try? container.decode(Bool.self, forKey: .backgroundLocationUpdates)) ?? Constant.Config.Location.backgroundLocationUpdates
            distanceFilter = (try? container.decode(Double.self, forKey: .distanceFilter)) ?? Constant.Config.Location.distanceFilter
            desiredAccuracy = (try? container.decode(Double.self, forKey: .desiredAccuracy)) ?? Constant.Config.Location.desiredAccuracy
            permissionType = (try? container.decode(PermissionType.self, forKey: .permissionType)) ?? PermissionType(rawValue: Constant.Config.Location.permissionType) ?? .always
            showsBackgroundLocationIndicator = (try? container.decode(Bool.self, forKey: .showsBackgroundLocationIndicator)) ?? Constant.Config.Location.showsBackgroundLocationIndicator
            pausesLocationUpdatesAutomatically = (try? container.decode(Bool.self, forKey: .pausesLocationUpdatesAutomatically)) ?? Constant.Config.Location.pausesLocationUpdatesAutomatically
        }

        public func encode(to encoder: Encoder) throws {
            var container = encoder.container(keyedBy: Keys.self)
            try container.encode(onlySignificantLocationUpdates, forKey: .onlySignificantLocationUpdates)
            try container.encode(deferredLocationUpdatesDistance, forKey: .deferredLocationUpdatesDistance)
            try container.encode(deferredLocationUpdatesTimeout, forKey: .deferredLocationUpdatesTimeout)
            try container.encode(backgroundLocationUpdates, forKey: .backgroundLocationUpdates)
            try container.encode(distanceFilter, forKey: .distanceFilter)
            try container.encode(desiredAccuracy, forKey: .desiredAccuracy)
            try container.encode(permissionType, forKey: .permissionType)
            try container.encode(showsBackgroundLocationIndicator, forKey: .showsBackgroundLocationIndicator)
            try container.encode(pausesLocationUpdatesAutomatically, forKey: .pausesLocationUpdatesAutomatically)
        }
    }
}

extension Config {
    public struct Activity: Codable {
        public init() {
        }

//        enum Keys: String, CodingKey {
//        }

        public init(from decoder: Decoder) throws {
        }

        public func encode(to encoder: Encoder) throws {
        }
    }
}

extension Config {
    public struct Services: Codable {
        var types: [ServiceType]

        public init() {
            types = Constant.Config.Services.types.compactMap({ ServiceType(rawValue: $0) })
        }

        @objc public enum ServiceType: Int, Codable, CustomStringConvertible {
            case location
            case activity
            case health
            //        case heartbeat

            public var description: String {
                switch self {
                case .location:
                    return "location service"
                case .activity:
                    return "activity service"
                case .health:
                    return "health service"
                }
            }
            
            public var context: Int {
                switch self {
                case .location:
                    return Constant.Context.location
                case .activity:
                    return Constant.Context.activity
                case .health:
                    return Constant.Context.health
                }
            }
        }

        enum Keys: String, CodingKey {
            case types = "types"
        }

        public init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: Keys.self)
            types = (try? container.decode([ServiceType].self, forKey: .types))
                ?? Constant.Config.Services.types.compactMap({ ServiceType(rawValue: $0) })
        }

        public func encode(to encoder: Encoder) throws {
            var container = encoder.container(keyedBy: Keys.self)
            try container.encode(types, forKey: .types)
        }
    }
}

extension Config {
    public struct Collection: Codable {
        public var isFiltering: Bool

        public init() {
            isFiltering = Constant.Config.Collection.isFiltering
        }

        enum Keys: String, CodingKey {
            case isFiltering = "is_Filtering"
        }

        public init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: Keys.self)
            isFiltering = (try? container.decode(Bool.self, forKey: .isFiltering)) ?? Constant.Config.Collection.isFiltering
        }

        public func encode(to encoder: Encoder) throws {
            var container = encoder.container(keyedBy: Keys.self)
            try container.encode(isFiltering, forKey: .isFiltering)
        }
    }
}

extension Config {
    public struct HeartbeatService: Codable {
        
        public var pingInterval:     TimeInterval
        public var toPing:           Bool
        
        public init() {
            pingInterval = Constant.Config.Heartbeat.pingInterval
            toPing       = Constant.Config.Heartbeat.toPing
        }
        
        enum Keys: String, CodingKey {
            case pingInterval = "ping_interval"
            case toPing       = "to_ping"
        }
        
        public init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: Keys.self)
            pingInterval  = (try? container.decode(TimeInterval.self, forKey: .pingInterval)) ?? Constant.Config.Heartbeat.pingInterval
            toPing        = (try? container.decode(Bool.self, forKey: .toPing)) ?? Constant.Config.Heartbeat.toPing
        }
        
        public func encode(to encoder: Encoder) throws {
            var container = encoder.container(keyedBy: Keys.self)
            try container.encode(pingInterval, forKey: .pingInterval)
            try container.encode(toPing,       forKey: .toPing)
        }
    }
}

