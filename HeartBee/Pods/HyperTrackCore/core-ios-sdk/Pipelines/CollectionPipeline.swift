//
//  CollectionPipeline.swift
//  core-ios-sdk
//
//  Created by Ashish Asawa on 13/06/18.
//  Copyright © 2018 www.hypertrack.com. All rights reserved.
//

import Foundation
import os

//TODO: @objc(HTCoreCollectionPipeline) public

final class CollectionPipeline: AbstractCollectionPipeline {
    func sendEvents<T>(events: [T], eventCollectedIn collectionType: EventCollectionType) where T : AbstractServiceData {
        self.execute(input: CollectionPipeline.ExecuteInput(events: events, collectionType: collectionType))
    }
    
    func sendEvents<T>(events: [T]) where T : AbstractServiceData {
        self.execute(input: CollectionPipeline.ExecuteInput(events: events, collectionType: collectionType))
    }
    
    fileprivate weak var config:    AbstractCollectionConfig?
    fileprivate weak var eventBus:  AbstractEventBus?
    fileprivate weak var databaseManager:  AbstractDatabaseManager?
    fileprivate weak var appState:         AbstractAppState?
    fileprivate weak var logger:         AbstractLogger?
    fileprivate let serialQueue  =  DispatchQueue(label: "com.hypertrack.cp.serial")
    fileprivate var  collectionType   = EventCollectionType.online
    
    // pipeline steps
    fileprivate let stepOne: AbstractPipelineStep<[AbstractServiceData], [Event]>
    fileprivate let stepTwo: AbstractPipelineStep<Pipeline.Collection.Input.DatabaseWrite, Bool>
    var context: Int {
        return Constant.Context.collectionPipeline
    }
    var isExecuting: Bool = false
    
    struct Input {
        let config: AbstractCollectionConfig?
        let eventBus: AbstractEventBus?
        let databaseManager: AbstractDatabaseManager?
        let appState: AbstractAppState?
        let logger: AbstractLogger?
    }
    
    struct ExecuteInput {
        let events:[AbstractServiceData]
        let collectionType: EventCollectionType
    }
    
    public init(input: Input) {
        self.config = input.config
        self.eventBus = input.eventBus
        self.databaseManager = input.databaseManager
        self.appState   = input.appState
        self.logger   = input.logger
        stepOne = CollectionMappingEntity()
        stepTwo = CollectionWriteDataBaseEntity(config: input.config)
        self.eventBus?.addObserver(self, selector: #selector(self.heartbeatStatusChanged(_:)), name: Constant.Notification.HeartbeatService.StatusChangedEvent.name)
        cleanup()
    }
    
    /*
     It will check, if there are previous online enteries, which are stale now
     and move them to offline table
     IMP to call on sdk restart
     */
    private func cleanup() {
        guard let appState  = self.appState else { return  }
        if appState.isSessionLaunchedInOffline() {
            moveOnlineToOffline()
        }
    }
    
    /*
     This will move data from online bucket to offline bucket.
     */
    private func moveOnlineToOffline() {
        self.databaseManager?.moveData(fromCollectionType: EventCollectionType.online, to: EventCollectionType.offline, completionHandler: { [weak self] success in
            if !success {
                self?.logger?.logError("Failed to move online data to offline", context: Constant.Context.collectionPipeline)
            } else {
                self?.logger?.logDebug("Successfully move online data to offline", context: Constant.Context.collectionPipeline)
            }
        })
    }
    
}

extension CollectionPipeline {
    @objc func heartbeatStatusChanged(_ notif: Notification) {
        guard let status = notif.userInfo?[Constant.Notification.HeartbeatService.StatusChangedEvent.key] as? HeartbeatService.Status else {
            return
        }
        switch status {
        case .disconnect:
            self.collectionType = .offline
            moveOnlineToOffline()
        default:
            self.collectionType = .online
        }
    }
}

extension CollectionPipeline: AbstractPipeline {
    func execute(completionHandler: ((CoreError?) -> Void)?) {
    }
    
    //TODO:  @objc public
    func execute(input: ExecuteInput) {
        //TODO: change unowned to weak
        setState(.executing)
        let database = databaseManager?.getDatabaseManager(input.collectionType)
        self.stepOne.execute(input: input.events)
            .continueWithTask(Executor.queue(serialQueue), continuation: { [unowned self] (task) -> Task<Bool> in
                switch task.mapTaskToResult() {
                case .success(let result):
                    return self.stepTwo.execute(input: Pipeline.Collection.Input.DatabaseWrite(events: result, database: database))
                case .failure(let error):
                    throw error
                }
            }).continueOnSuccessWith { [unowned self] (result) in
                self.setState(.success)
                self.eventBus?.post(name: Constant.Notification.Database.DataAvailableEvent.name, userInfo: [Constant.Notification.Database.DataAvailableEvent.key: input.collectionType])
        }
    }
}

