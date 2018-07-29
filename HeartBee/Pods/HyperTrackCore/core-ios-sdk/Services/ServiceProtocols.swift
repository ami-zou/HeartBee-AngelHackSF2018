//
//  ServiceProtocols.swift
//  core-ios-sdk
//
//  Created by Ashish Asawa on 04/06/18.
//  Copyright © 2018 www.hypertrack.com. All rights reserved.
//

import Foundation

//@objc(HTCoreAbstractEvent) public

public enum ServiceError: Error {
    case hardwareNotSupported
    case permissionNotTaken
    case userDenied
    case osDenied
    case unknown
}

public protocol AbstractServiceData {
    func getType()         ->      EventType
    func getId()           ->      String
    func getRecordedAt()   ->      Date
    func getJSONdata()     ->      String           //TODO: Decodable, encodable data
}

public protocol AbstractCollectionPipeline: class {
    func sendEvents<T: AbstractServiceData>(events: [T])
    func sendEvents<T: AbstractServiceData>(events: [T], eventCollectedIn collectionType: EventCollectionType)
}

public protocol AbstractService: class {
    var collectionProtocol: AbstractCollectionPipeline? {
        get set
    }
    
    var eventBus: AbstractEventBus? {
        get set
    }
    func setEventUpdatesDelegate(_ delegate: EventUpdatesDelegate?)
    func startService() throws -> ServiceError?
    func stopService()
    func isServiceRunning() -> Bool
    func isAuthorized() -> Bool
    // requestpermission, permissionstatus
    
}

extension AbstractService {
    public func setEventUpdatesDelegate(_ delegate: EventUpdatesDelegate?) {
    }
}

