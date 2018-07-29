//
//  TransmissionPipeline.swift
//  core-ios-sdk
//
//  Created by Atul Manwar on 11/06/18.
//  Copyright © 2018 www.hypertrack.com. All rights reserved.
//

import Foundation

protocol AbstractTransmissionPipeline: AbstractPipeline {
    var config: AbstractTransmissionConfig? { get }
    var deviceId: GetDeviceIdProtocol? { get }
    var eventBus: AbstractEventBus? { get }
    var database: EventsFMDBDatabaseManager? { get }
    var serialQueue: DispatchQueue { get }
    var reachabilityStep: AbstractPipelineStep<Void, Bool> { get }
    var databaseReadStep: AbstractPipelineStep<Pipeline.Transmission.Input.ReadDatabase, Pipeline.Transmission.Input.Mapper> { get }
    var mapperStep: AbstractPipelineStep<Pipeline.Transmission.Input.Mapper, Pipeline.Transmission.Input.Network> { get }
    var networkStep: AbstractPipelineStep<Pipeline.Transmission.Input.Network, Pipeline.Transmission.Input.WriteDatabase> { get }
    var databaseWriteStep: AbstractPipelineStep<Pipeline.Transmission.Input.WriteDatabase, Pipeline.Transmission.Input.PipelineEnded> { get }
}

extension AbstractTransmissionPipeline {
    public func execute(completionHandler: ((CoreError?) -> Void)?) {
        //TODO: change unowned to weak
        setState(.executing)
        self.reachabilityStep.execute(input: ())
            .continueWithTask(Executor.queue(serialQueue), continuation: { [unowned self] (task) -> Task<Pipeline.Transmission.Input.Mapper> in
                switch task.mapTaskToResult() {
                case .success(_):
                    return self.databaseReadStep.execute(input: Pipeline.Transmission.Input.ReadDatabase(deviceId: self.deviceId?.getDeviceId() ?? "") )
                case .failure(let error):
                    completionHandler?(error)
                    throw error
                }
            })
            .continueWithTask(Executor.queue(serialQueue), continuation: { [unowned self] (task) -> Task<Pipeline.Transmission.Input.Network> in
                switch task.mapTaskToResult() {
                case .success(let result):
                    return self.mapperStep.execute(input: result)
                case .failure(let error):
                    completionHandler?(error)
                    throw error
                }
            })
            .continueWithTask(Executor.queue(serialQueue), continuation: { [unowned self] (task) -> Task<Pipeline.Transmission.Input.WriteDatabase> in
                switch task.mapTaskToResult() {
                case .success(let result):
                    return self.networkStep.execute(input: result)
                case .failure(let error):
                    completionHandler?(error)
                    throw error
                }
            })
            .continueWithTask(Executor.queue(serialQueue), continuation: { [unowned self] (task) -> Task<Pipeline.Transmission.Input.PipelineEnded> in
                switch task.mapTaskToResult() {
                case .success(let result):
                    return self.databaseWriteStep.execute(input: result)
                case .failure(let error):
                    completionHandler?(error)
                    throw error
                }
            })
            .continueWith(Executor.queue(serialQueue), continuation: { [unowned self] (task) in
                switch task.mapTaskToResult() {
                case .success(let result):
                    self.setState(.success)
                    if let batchSize = self.config?.transmission.batchSize, UInt(result.events.count) < batchSize {
                        self.eventBus?.post(name: Constant.Notification.Transmission.DataSentEvent.name, userInfo: nil)
                        completionHandler?(nil)
                    } else {
                        self.execute(completionHandler: completionHandler)
                    }
                case .failure(let error):
                    self.setState(.failure(error))
                    completionHandler?(error)
                    throw error
                }
            })
    }

}

public final class TransmissionPipeline {
    internal weak var config: AbstractTransmissionConfig?
    internal weak var eventBus: AbstractEventBus?
    internal weak var database: EventsFMDBDatabaseManager?
    internal weak var deviceId: GetDeviceIdProtocol?
    internal let serialQueue: DispatchQueue
    internal var inProgress = false
    internal let batchSize: UInt
    public var context: Int {
        return Constant.Context.transmissionPipeline
    }
    public var isExecuting: Bool = false
    
    internal let reachabilityStep: AbstractPipelineStep<Void, Bool>
    internal let databaseReadStep: AbstractPipelineStep<Pipeline.Transmission.Input.ReadDatabase, Pipeline.Transmission.Input.Mapper>
    internal let mapperStep: AbstractPipelineStep<Pipeline.Transmission.Input.Mapper, Pipeline.Transmission.Input.Network>
    internal let networkStep: AbstractPipelineStep<Pipeline.Transmission.Input.Network, Pipeline.Transmission.Input.WriteDatabase>
    internal let databaseWriteStep: AbstractPipelineStep<Pipeline.Transmission.Input.WriteDatabase, Pipeline.Transmission.Input.PipelineEnded>

    init(input: Input) {
        config = input.config
        eventBus = input.eventBus
        database = input.database
        batchSize = input.batchSize
        deviceId = input.deviceId
        serialQueue  =  DispatchQueue(label: input.queueName)
        reachabilityStep = ReachabilityManager(config: input.config, eventBus: input.eventBus)
        databaseReadStep = TransmissionReadDatabaseStep(input: Transmission.Input.Database(batchSize: input.batchSize, config: input.config, database: input.database))
        mapperStep = input.mapperStep
        networkStep = TransmissionNetworkStep(input: Transmission.Input.Network(config: input.config, apiClient: input.apiClient))
        databaseWriteStep = TransmissionWriteDatabaseStep(input: Transmission.Input.Database(batchSize: input.batchSize, config: input.config, database: input.database))
        self.eventBus?.addObserver(self, selector: #selector(execute), name: Constant.Notification.Transmission.SendDataEvent.name)
    }
    
    @objc func execute() {
        execute(completionHandler: nil)
    }
    
    struct Input {
        let queueName: String
        let batchSize: UInt
        let config: AbstractTransmissionConfig?
        let eventBus: AbstractEventBus?
        let database: EventsFMDBDatabaseManager?
        let apiClient: AbstractAPIClient?
        let deviceId: GetDeviceIdProtocol?
        let mapperStep: AbstractPipelineStep<Pipeline.Transmission.Input.Mapper, Pipeline.Transmission.Input.Network>
    }
}

extension TransmissionPipeline: AbstractTransmissionPipeline {
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

protocol AbstractTransmissionManager: AbstractPipeline {
    func getTransmissionPipeline(_ collectionType: EventCollectionType) -> AbstractTransmissionPipeline?
}

public final class TransmissionManager {
    struct Input {
        let collectionTypes: [EventCollectionType]
        let config: AbstractTransmissionConfig
        let eventBus: AbstractEventBus?
        let databaseManager: AbstractDatabaseManager?
        let apiClient: AbstractAPIClient?
        let deviceId: GetDeviceIdProtocol?
    }
    fileprivate var instances: [EventCollectionType: TransmissionPipeline] = [:]
    public var context: Int {
        return Constant.Context.transmissionPipeline
    }
    public var isExecuting: Bool = false
    
    init(input: Input) {
        let queueNamePrefix = "com.hypertrack.tp.serial"
        input.collectionTypes.forEach({
            instances[$0] = TransmissionPipeline(input: TransmissionPipeline.Input(queueName: "\(queueNamePrefix).\($0.tableName())", batchSize: $0 == .online ? input.config.transmission.batchSize : 0, config: input.config, eventBus: input.eventBus, database: input.databaseManager?.getDatabaseManager($0), apiClient: input.apiClient, deviceId: input.deviceId, mapperStep: $0 == .online ? TransmissionEventMapper() : TransmissionOfflineEventMapper()))
        })
    }
}

extension TransmissionManager: AbstractTransmissionManager {
    func getTransmissionPipeline(_ collectionType: EventCollectionType) -> AbstractTransmissionPipeline? {
        return instances[collectionType]
    }
    
    public func execute(completionHandler: ((CoreError?) -> Void)?) {
        guard !isExecuting else { return }
        setState(.executing)
        instances[.online]?.execute(completionHandler: { [weak self] (error) in
            if let error = error {
                completionHandler?(error)
                self?.setState(.failure(error))
            } else {
                self?.instances[.offline]?.execute(completionHandler: { (error) in
                    if let error = error {
                        self?.setState(.failure(error))
                    } else {
                        self?.setState(.success)
                    }
                    completionHandler?(error)
                })
            }
        })
    }
}
