//
//  Provider.swift
//  core-ios-sdk
//
//  Created by Atul Manwar on 31/05/18.
//  Copyright © 2018 www.hypertrack.com. All rights reserved.
//

import Foundation

public final class Provider {
    //Basic components
    static let logger: AbstractLogger = LoggerWrapper().lumberJack
    static let eventBus: AbstractEventBus = EventBusWrapper().center
    static let fileStorage: AbstractFileStorage = FileStorage(logger)
    static let appState: AbstractAppState = AppState(dataStore: dataStore, logger: logger)

    //Services
    static let databaseManager: AbstractDatabaseManager = DatabaseManager(dbInfo: DatabaseManager.Info(name: Constant.Database.name, collectionTypes: [.online, .offline]))
    static let configManager: AbstractConfigManager = ConfigManager(storage: fileStorage, logger: logger)
    public static let dataStore: AbstractReadWriteDataStore = ReadWriteDataStoreWrapper(logger: Provider.logger, config: configManager.config).defaults
    static let serviceManager: AbstractServiceManager = ServiceManager(serviceTypes: configManager.config.services.types, config: configManager.config, logger: logger, eventBus: eventBus, appState: appState, collection: collectionPipeline, factory: ServiceFactory())
    static let authManager: AuthTokenProvider = AuthManager(config: configManager.config, dataStore: dataStore, serviceManager: serviceManager)
    static let apiClient: AbstractAPIClient = APIClient(configManager.config, tokenProvider: authManager, detailsProvider: appState)
    
    
    //Pipelines
    static let initPipeline: InitializationPipeline = InitializationPipeline(config: configManager.config, serviceManager: serviceManager, appState: appState, eventBus: eventBus, tokenProvider: authManager)
    static let collectionPipeline: AbstractCollectionPipeline = CollectionPipeline(input: CollectionPipeline.Input(config: configManager.config, eventBus: eventBus, databaseManager: databaseManager, appState: appState, logger: logger))
    static let transmissionPipeline: AbstractTransmissionManager = TransmissionManager(input: TransmissionManager.Input(collectionTypes: [.online, .offline], config: configManager.config, eventBus: eventBus, databaseManager: databaseManager, apiClient: apiClient, deviceId: appState))

    static let dispatch: AbstractDispatch = Dispatch(eventBus: eventBus, config: configManager.config, context: DispatchStrategyContext(), transmission: transmissionPipeline)
    
    static let heartbeat = HeartbeatService(config:configManager.config, eventBus: eventBus, appState: appState, apiClient: apiClient, logger: logger, info: appState.getHeartbeatInfo())
    
}
