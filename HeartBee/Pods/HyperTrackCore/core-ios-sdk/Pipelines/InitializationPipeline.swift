//
//  InitializationPipeline.swift
//  core-ios-sdk
//
//  Created by Atul Manwar on 06/06/18.
//  Copyright © 2018 www.hypertrack.com. All rights reserved.
//

import Foundation

public protocol AbstractPipeline: PipelineLogging {
    var isExecuting: Bool { get set }
    func execute(completionHandler: ((CoreError?) -> Void)?)
}

extension AbstractPipeline {
    func setState(_ type: Pipeline.State, file: StaticString = #file, function: StaticString = #function, line: UInt = #line) {
        isExecuting = type.isExecuting
        log(type, file: file, function: function, line: line)
    }
}

public protocol AbstractInitPipeline: AbstractPipeline {
    func getLocationServiceInitializationPipeline() -> AbstractPipeline
    func getActivityServiceInitializationPipeline() -> AbstractPipeline
}

public final class InitializationPipeline {
    fileprivate var config: AbstractConfig
    fileprivate let stepOne: AbstractPipelineStep<Void, Bool>
    fileprivate let stepTwo: AbstractPipelineStep<Bool, Response>
    fileprivate weak var serviceManager: AbstractServiceManager?
    fileprivate weak var appState: AbstractAppState?
    fileprivate lazy var locationServicesInitPipeline: LocationServiceInitializationPipeline = {
        return LocationServiceInitializationPipeline(config: config, serviceManager: serviceManager)
    }()
    fileprivate lazy var activityServicesInitPipeline: ActivityServiceInitializationPipeline = {
        return ActivityServiceInitializationPipeline(config: config, serviceManager: serviceManager)
    }()
    fileprivate let serialQueue  =  DispatchQueue(label: "com.hypertrack.ip.serial")
    fileprivate weak var eventBus: AbstractEventBus?
    public var context: Int {
        return Constant.Context.initPipeline
    }
    public var isExecuting: Bool = false
    
    public init(config: AbstractConfig, serviceManager: AbstractServiceManager?, appState: AbstractAppState?, eventBus: AbstractEventBus?, tokenProvider: AuthTokenProvider?) {
        self.config = config
        self.serviceManager = serviceManager
        self.appState = appState
        self.eventBus = eventBus
        stepOne = CheckAuthorizationTokenStep(input: Initialization.Input.ReAuthorize(tokenProvider: tokenProvider, apiClient: Provider.apiClient, detailsProvider: appState))
        stepTwo = InitDeviceRegistrationEntity(apiClient: Provider.apiClient, appState: Provider.appState)
    }
}

extension InitializationPipeline: AbstractInitPipeline {
    public func execute(completionHandler: ((CoreError?) -> Void)?) {
        setState(.executing)
        preInit()
        stepOne.execute(input: ())
            .continueWithTask(Executor.queue(serialQueue), continuation: { [unowned self] (task) -> Task<Response> in
                switch task.mapTaskToResult() {
                case .success(let result):
                    return self.stepTwo.execute(input: result)
                case .failure(let error):
                    completionHandler?(error)
                    throw error
                }
            })
            .continueWith(Executor.queue(serialQueue), continuation: { [weak self] (task) in
                switch task.mapTaskToResult() {
                case .success(_):
                    self?.appState?.isAppInitialized = true
                    if self?.appState?.isPausedByUser == false {
                        self?.serviceManager?.startAllServices()
                    }
                    if let data = task.result?.data {
                        let heartbeatInfo = try JSONDecoder.hyperTrackDecoder.decode(HeartbeatInfo.self, from: data)
                        self?.appState?.saveHeartbeatInfo(info: heartbeatInfo)
                        Provider.heartbeat.startService()
                    }
                    completionHandler?(nil)
                    self?.setState(.success)
                case .failure(let error):
                    self?.setState(.failure(error))
                    if self?.appState?.isPausedByUser == false && self?.appState?.isAppInitialized == true {
                        Provider.heartbeat.startService()
                        self?.serviceManager?.startAllServices()
                        completionHandler?(nil)
                    } else {
                        completionHandler?(error)
                        throw error
                    }
                }
            })
    }
    
    public func getLocationServiceInitializationPipeline() -> AbstractPipeline {
        return locationServicesInitPipeline
    }
    
    public func getActivityServiceInitializationPipeline() -> AbstractPipeline {
        return activityServicesInitPipeline
    }
    
    public func preInit() {
        _ = Provider.transmissionPipeline
        _ = Provider.dispatch
    }
}

extension Task {
    func mapTaskToResult() -> Result<TResult> {
        if let error = error as? CoreError {
            return Result.failure(error)
        } else if let result = result {
            return Result.success(result)
        } else {
            return Result.failure(CoreError(.unknown))
        }
    }
}
