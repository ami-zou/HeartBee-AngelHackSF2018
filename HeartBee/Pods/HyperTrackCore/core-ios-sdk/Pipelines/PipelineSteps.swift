//
//  PipelineSteps.swift
//  core-ios-sdk
//
//  Created by Atul Manwar on 11/06/18.
//  Copyright © 2018 www.hypertrack.com. All rights reserved.
//

import Foundation

public protocol PipelineLogging: class {
    var context: Int { get }
}


extension PipelineLogging {
    func log(_ type: Pipeline.State, file: StaticString = #file, function: StaticString = #function, line: UInt = #line) {
        let className = String(describing: Self.self)
        switch type {
        case .executing:
            Provider.logger.logDebug("executing \(className)", context: context, file: file, function: function, line: line)
        case .failure(let error):
            Provider.logger.logError("failed \(className) because \(error.coreErrorDescription)", context: context, file: file, function: function, line: line)
        case .success:
            Provider.logger.logDebug("succeeded \(className)", context: context, file: file, function: function, line: line)
        }
    }
}

public class AbstractPipelineStep<Input, Output>: PipelineLogging {
    public var context: Int {
        return Constant.Context.pipelineStep
    }
    
    public func execute(input: Input) -> Task<Output> {
        return Task<Output>()
    }
    
    func setState(_ type: Pipeline.State, file: StaticString = #file, function: StaticString = #function, line: UInt = #line) {
        log(type, file: file, function: function, line: line)
    }
}

protocol TransmissionDatabaseStepInput {
    var batchSize: UInt { get }
    var config: AbstractTransmissionConfig? { get }
    var database: EventsFMDBDatabaseManager? { get }
}

protocol TransmissionNetworkStepInput {
    var config: AbstractNetworkConfig? { get }
    var apiClient: AbstractAPIClient? { get }
}

enum Transmission {
    enum Input {
        struct Database: TransmissionDatabaseStepInput {
            let batchSize: UInt
            let config: AbstractTransmissionConfig?
            let database: EventsFMDBDatabaseManager?
        }
        struct Network: TransmissionNetworkStepInput {
            let config: AbstractNetworkConfig?
            let apiClient: AbstractAPIClient?
        }
    }
}

protocol ReAuthorizeStepInput {
    var tokenProvider: AuthTokenProvider? { get }
    var apiClient: AbstractAPIClient? { get }
    var detailsProvider: AccountAndDeviceDetailsProvider? { get }
}

enum Initialization {
    enum Input {
        struct ReAuthorize: ReAuthorizeStepInput {
            let tokenProvider: AuthTokenProvider?
            let apiClient: AbstractAPIClient?
            let detailsProvider: AccountAndDeviceDetailsProvider?
        }
    }
}

//
public enum Pipeline {
    enum Collection {
        enum Input {
            struct DatabaseWrite {
                let events: [Event]
                let database: EventsFMDBDatabaseManager?
            }
        }
    }
    enum Transmission {
        enum Input {
            struct ReadDatabase {
                let deviceId: String
            }
            struct Mapper {
                let events: [Event]
                let deviceId: String
            }
            struct Network {
                let events: [Event]
                let payload: [Payload]
            }
            struct WriteDatabase {
                let events: [Event]
                let response: Response
            }
            struct PipelineEnded {
                let events: [Event]
            }
        }
    }
    public enum State {
        case executing
        case failure(Error)
        case success
        
        public var isExecuting: Bool {
            switch self {
            case .executing:
                return true
            default:
                return false
            }
        }
    }
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

public protocol AbstractReachabilityManager {
    var isReachable: Bool { get }
}

public final class ReachabilityManager: AbstractPipelineStep<Void, Bool>, AbstractReachabilityManager {
    typealias ReachabilityEvent = Constant.Notification.Network.ReachabilityEvent
    public private(set)  var isReachable: Bool = false {
        didSet {
            eventBus?.post(name: ReachabilityEvent.name, userInfo: [ReachabilityEvent.key : isReachable])
        }
    }
    fileprivate let reachability: Reachability
    fileprivate weak var config: AbstractNetworkConfig?
    fileprivate weak var eventBus: AbstractEventBus?
    fileprivate var host: String {
        return config?.network.host ?? Constant.Config.Network.host
    }
    
    public init(config: AbstractNetworkConfig?, eventBus: AbstractEventBus?) {
        self.config = config
        self.eventBus = eventBus
        reachability = Reachability(hostName: "www.google.com")//config?.network.host ?? Constant.Config.Network.host
        super.init()
        reachability.reachableBlock = { [weak self] (reach) in
            self?.isReachable = true
        }
        reachability.unreachableBlock = { [weak self] (reach) in
            self?.isReachable = false
        }
        reachability.startNotifier()
    }
    
    public override func execute(input: Void) -> Task<Bool> {
        setState(.executing)
        let taskSource = TaskCompletionSource<Bool>()
        if isReachable {
            taskSource.set(result: isReachable)
            setState(.success)
        } else {
            let error = CoreError(.networkDisconnected)
            taskSource.set(error: error)
            setState(.failure(error))
        }
        return taskSource.task
    }
    
    deinit {
        reachability.stopNotifier()
    }
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

final class TransmissionReadDatabaseStep: AbstractPipelineStep<Pipeline.Transmission.Input.ReadDatabase, Pipeline.Transmission.Input.Mapper>, TransmissionDatabaseStepInput {
    internal weak var config: AbstractTransmissionConfig?
    internal weak var database: EventsFMDBDatabaseManager?
    internal let batchSize: UInt
    
    init(input: TransmissionDatabaseStepInput) {
        self.config = input.config
        self.database = input.database
        self.batchSize = input.batchSize
        super.init()
    }
    
    override func execute(input: Pipeline.Transmission.Input.ReadDatabase) -> Task<Pipeline.Transmission.Input.Mapper> {
        setState(.executing)
        let taskSource = TaskCompletionSource<Pipeline.Transmission.Input.Mapper>()
        database?.fetch(count: batchSize, result: { [weak self] (result) in
            switch result {
            case .success(let events):
                if events.count > 0 {
                    taskSource.set(result: Pipeline.Transmission.Input.Mapper(events: events, deviceId: input.deviceId))
                    self?.setState(.success)
                } else {
                    let error = CoreError(.databaseReadFailed)
                    taskSource.set(error: error)
                    self?.setState(.failure(error))
                }
            case .failure:
                let error = CoreError(.databaseReadFailed)
                taskSource.set(error: error)
                self?.setState(.failure(error))
            }
        })
        return taskSource.task
    }
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

final class TransmissionEventMapper: AbstractPipelineStep<Pipeline.Transmission.Input.Mapper, Pipeline.Transmission.Input.Network> {
    override init() {
    }
    
    override func execute(input: Pipeline.Transmission.Input.Mapper) -> Task<Pipeline.Transmission.Input.Network> {
        setState(.executing)
        let taskSource = TaskCompletionSource<Pipeline.Transmission.Input.Network>()
        let events = input.events.compactMap({ (event) -> Payload? in
            var params: Payload!
            switch event.jsonDict() {
            case .success(let eventDict):
                params = eventDict
                params[Constant.ServerKeys.Event.deviceId] = input.deviceId
                return params
            case .failure:
                return nil
            }
        })
        taskSource.set(result: Pipeline.Transmission.Input.Network(events: input.events, payload: events))
        setState(.success)
        return taskSource.task
    }
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

final class TransmissionOfflineEventMapper: AbstractPipelineStep<Pipeline.Transmission.Input.Mapper, Pipeline.Transmission.Input.Network> {
    override init() {
    }
    
    override func execute(input: Pipeline.Transmission.Input.Mapper) -> Task<Pipeline.Transmission.Input.Network> {
        setState(.executing)
        let taskSource = TaskCompletionSource<Pipeline.Transmission.Input.Network>()
        let events = input.events.compactMap({ (event) -> Payload? in
            var params: Payload!
            switch event.jsonDict() {
            case .success(let eventDict):
                params = eventDict
                params[Constant.ServerKeys.Event.deviceId] = input.deviceId
                return params
            case .failure:
                return nil
            }
        })
        taskSource.set(result: Pipeline.Transmission.Input.Network(events: input.events, payload: [[Constant.ServerKeys.Event.type: EventType.deviceReconnected.rawValue, Constant.ServerKeys.Event.data: [Constant.ServerKeys.Event.events: events], Constant.ServerKeys.Event.deviceId: input.deviceId, Constant.ServerKeys.Event.recordedAt:
            DateFormatter.iso8601Full.string(from: Date()), Constant.ServerKeys.Event.id: UUID().uuidString]]))
        setState(.success)
        return taskSource.task
    }
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

final class TransmissionNetworkStep: AbstractPipelineStep<Pipeline.Transmission.Input.Network, Pipeline.Transmission.Input.WriteDatabase>, TransmissionNetworkStepInput {
    internal weak var config: AbstractNetworkConfig?
    internal weak var apiClient: AbstractAPIClient?
    
    init(input: TransmissionNetworkStepInput) {
        self.config = input.config
        self.apiClient = input.apiClient
        super.init()
    }
    
    override func execute(input: Pipeline.Transmission.Input.Network) -> Task<Pipeline.Transmission.Input.WriteDatabase> {
        setState(.executing)
        let taskSource = TaskCompletionSource<Pipeline.Transmission.Input.WriteDatabase>()
        guard let apiClient = apiClient else {
            let error = CoreError(.unknown)
            taskSource.set(error: error)
            setState(.failure(error))
            return taskSource.task
        }
        apiClient.makeRequest(ApiRouter.sendEvent(input.payload))
            .continueWith(continuation: { [weak self] (task) -> Void in
                if let error = task.error {
                    taskSource.set(error: error)
                    self?.setState(.failure(error))
                } else if let result = task.result {
                    taskSource.set(result: Pipeline.Transmission.Input.WriteDatabase(events: input.events, response: result))
                    self?.setState(.success)
                } else {
                    let error = CoreError(.unknown)
                    taskSource.set(error: error)
                    self?.setState(.failure(error))
                }
            })
        return taskSource.task
    }
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

final class TransmissionWriteDatabaseStep: AbstractPipelineStep<Pipeline.Transmission.Input.WriteDatabase, Pipeline.Transmission.Input.PipelineEnded>, TransmissionDatabaseStepInput {
    internal var batchSize: UInt = 0
    internal weak var config: AbstractTransmissionConfig?
    internal weak var database: EventsFMDBDatabaseManager?
    
    init(input: TransmissionDatabaseStepInput) {
        self.config = input.config
        self.database = input.database
        super.init()
    }
    
    override func execute(input: Pipeline.Transmission.Input.WriteDatabase) -> Task<Pipeline.Transmission.Input.PipelineEnded> {
        setState(.executing)
        let taskSource = TaskCompletionSource<Pipeline.Transmission.Input.PipelineEnded>()
        if let error = input.response.error {
            taskSource.set(error: error)
            setState(.failure(error))
        } else {
            database?.delete(items: input.events, result: { [weak self] (result) in
                switch result {
                case .success:
                    taskSource.set(result: Pipeline.Transmission.Input.PipelineEnded(events: input.events))
                    self?.setState(.success)
                case .failure:
                    let error = CoreError(.databaseWriteFailed)
                    taskSource.set(error: error)
                    self?.setState(.failure(error))
                }
            })
        }
        return taskSource.task
    }
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

final class LocationPermissionStep: AbstractPipelineStep<Void, Bool> {
    fileprivate weak var serviceManager: AbstractServiceManager?
    
    init(serviceManager: AbstractServiceManager?) {
        self.serviceManager = serviceManager
    }
    
    override func execute(input: Void) -> Task<Bool> {
        setState(.executing)
        let taskSource = TaskCompletionSource<Bool>()
        if let locationService = serviceManager?.getService(.location) as? AbstractLocationService {
            locationService.requestPermissions { [weak self] (authorized) in
                if authorized {
                    taskSource.set(result: true)
                    self?.setState(.success)
                } else {
                    let error = CoreError(.locationPermissionsDenied)
                    taskSource.set(error: error)
                    self?.setState(.failure(error))
                }
            }
        } else {
            let error = CoreError(.unknownService)
            taskSource.set(error: error)
            setState(.failure(error))
        }
        return taskSource.task
    }
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

final class ActivityPermissionStep: AbstractPipelineStep<Void, Bool> {
    fileprivate weak var serviceManager: AbstractServiceManager?
    
    init(serviceManager: AbstractServiceManager?) {
        self.serviceManager = serviceManager
    }
    
    override func execute(input: Void) -> Task<Bool> {
        setState(.executing)
        let taskSource = TaskCompletionSource<Bool>()
        if let activityService = serviceManager?.getService(.activity) as? PrivateDataAccessProvider {
            activityService.requestAccess(completionHandler: { [weak self] (result) in
                if let error = result.error {
                    taskSource.set(error: error)
                    self?.setState(.failure(error))
                } else {
                    switch result.accessLevel {
                    case .granted:
                        fallthrough
                    case .grantedAlways:
                        fallthrough
                    case .grantedWhenInUse:
                        taskSource.set(result: true)
                        self?.setState(.success)
                    default:
                        let error = CoreError(.activityPermissionsDenied)
                        taskSource.set(error: error)
                        self?.setState(.failure(error))
                    }
                }
            })
        } else {
            let error = CoreError(.unknownService)
            taskSource.set(error: error)
            setState(.failure(error))
        }
        return taskSource.task
    }
}


final class CollectionWriteDataBaseEntity: AbstractPipelineStep<Pipeline.Collection.Input.DatabaseWrite, Bool> {
    fileprivate weak var config:    AbstractCollectionConfig?
    fileprivate var isFiltering: Bool {
        return config?.collection.isFiltering ?? Constant.Config.Collection.isFiltering
    }
    
    init(config: AbstractCollectionConfig?) {
        self.config = config
        super.init()
    }
    
    override func execute(input: Pipeline.Collection.Input.DatabaseWrite) -> Task<Bool> {
        setState(.executing)
        let taskSource = TaskCompletionSource<Bool>()
        input.database?.insert(items: input.events, result: { [weak self] (result) in
            switch result {
            case .success(_):
                taskSource.set(result: true)
                self?.setState(.success)
            case .failure(_):
                let error = CoreError(.databaseWriteFailed)
                taskSource.set(error: error)
                self?.setState(.failure(error))
            }
        })
        return taskSource.task
    }
}

final class CollectionMappingEntity: AbstractPipelineStep<[AbstractServiceData], [Event]> {
    
    override func execute(input: [AbstractServiceData]) -> Task<[Event]> {
        setState(.executing)
        let taskSource = TaskCompletionSource<[Event]>()
        let events = input.map({
            return Event(type: $0.getType(), data: $0.getJSONdata(), id: $0.getId(), recordedAt: DateFormatter.iso8601Full.string(from: $0.getRecordedAt()))
        })
        if events.count > 0 {
            taskSource.set(result: events)
            setState(.success)
        } else {
            let error = CoreError(.sensorToDataMappingFailed)
            taskSource.set(error: error)
            setState(.failure(error))
        }
        return taskSource.task
    }
    
}

final class CheckAccountStatusStep: AbstractPipelineStep<Void, Bool> {
    fileprivate weak var tokenProvider: AuthTokenProvider?
    
    init(tokenProvider: AuthTokenProvider?) {
        self.tokenProvider = tokenProvider
    }
    
    override func execute(input: Void) -> Task<Bool> {
        guard let status = tokenProvider?.status, status == .active else {
            return Task<Bool>(false)
        }
        return Task<Bool>(true)
    }
}

final class CheckAuthorizationTokenStep: AbstractPipelineStep<Void, Bool> {
    internal var reauthStep: ReAuthorizeStep
    
    init(input: ReAuthorizeStepInput) {
        self.reauthStep = ReAuthorizeStep(input: input)
        super.init()
    }
    
    override func execute(input: Void) -> Task<Bool> {
        setState(.executing)
        let taskSource = TaskCompletionSource<Bool>()
        guard let status = reauthStep.tokenProvider?.status, status == .active else {
            let error = CoreError(.forbidden)
            taskSource.set(error: error)
            setState(.failure(error))
            return taskSource.task
        }
        if let token = reauthStep.tokenProvider?.authToken?.token, token != "" {
            taskSource.set(result: true)
        } else {
            reauthStep.execute(input: ()).continueWith { [weak self] (task) in
                if let error = task.error {
                    taskSource.set(error: error)
                    self?.setState(.failure(error))
                } else {
                    taskSource.set(result: true)
                    self?.setState(.success)
                }
            }
        }
        return taskSource.task
    }
}


final class ReAuthorizeStep: AbstractPipelineStep<Void, Response>, ReAuthorizeStepInput {
    internal weak var tokenProvider: AuthTokenProvider?
    internal weak var apiClient: AbstractAPIClient?
    internal weak var detailsProvider: AccountAndDeviceDetailsProvider?
    
    init(input: ReAuthorizeStepInput) {
        self.tokenProvider = input.tokenProvider
        self.apiClient = input.apiClient
        self.detailsProvider = input.detailsProvider
        super.init()
    }
    
    override func execute(input: Void) -> Task<Response> {
        setState(.executing)
        let taskSource = TaskCompletionSource<Response>()
        let accountIdKey = "account_id"
        guard let apiClient = apiClient, let deviceId = detailsProvider?.getDeviceId() else {
            let error = CoreError(.deviceIdBlank)
            taskSource.set(error: error)
            setState(.failure(error))
            return taskSource.task
        }
        apiClient.makeRequest(ApiRouter.getToken(deviceId: deviceId))
            .continueWith(continuation: { [weak self] (task) -> Void in
                if let error = task.error {
                    self?.setState(.failure(error))
                    taskSource.set(error: error)
                } else if let result = task.result, let data = result.data {
                    do {
                        if let dict = try JSONSerialization.jsonObject(with: data, options: JSONSerialization.ReadingOptions.allowFragments) as? [String: Any], let accountId = dict[accountIdKey] as? String {
                            self?.detailsProvider?.setAccountId(accountId)
                        }
                        self?.tokenProvider?.authToken = try JSONDecoder.hyperTrackDecoder.decode(AuthToken.self, from: data)
                        taskSource.set(result: result)
                        self?.setState(.success)
                    } catch {
                        self?.tokenProvider?.authToken = nil
                        let error = CoreError(ErrorType.parsingError)
                        taskSource.set(error: error)
                        self?.setState(.failure(error))
                    }
                } else {
                    let error = CoreError(.unknown)
                    taskSource.set(error: error)
                    self?.setState(.failure(error))
                }
            })
        return taskSource.task
    }
}


final class InitDeviceRegistrationEntity: AbstractPipelineStep<Bool, (Response)> {
    fileprivate weak var apiClient: AbstractAPIClient?
    fileprivate weak var appState: AbstractAppState?
    
    init(apiClient: AbstractAPIClient, appState: AbstractAppState?) {
        self.apiClient = apiClient
        self.appState = appState

        super.init()
    }
    
    override func execute(input: Bool) -> Task<(Response)> {
        setState(.executing)
        let taskSource = TaskCompletionSource<(Response)>()
        guard let apiClient = apiClient,
              let appState  = appState  else {
                let error = CoreError(.unknown)
                taskSource.set(error: error)
                setState(.failure(error))
            return taskSource.task
        }
        
        var payload: Payload? = nil
        switch appState.getDeviceData().jsonDict() {
        case .success(let dict):
            payload = dict
            payload?["account_id"] = appState.getAccountId()
        case .failure:
            let error = CoreError(.unknown)
            taskSource.set(error: error)
            setState(.failure(error))
        }
        if let payload = payload {
            apiClient.makeRequest(ApiRouter.deviceRegister(payload)).continueWith { [weak self] (task) -> Void in
                if let error = task.error {
                    taskSource.set(error: error)
                    self?.setState(.failure(error))
                } else if let result = task.result {
                    taskSource.set(result: result)
                    self?.setState(.success)
                } else {
                    let error = CoreError(.unknown)
                    taskSource.set(error: error)
                    self?.setState(.failure(error))
                }
            }
        }
        return taskSource.task
    }
}

extension Error {
    var coreErrorDescription: String {
        return (self as? CoreError)?.displayErrorMessage ?? localizedDescription
    }
}
