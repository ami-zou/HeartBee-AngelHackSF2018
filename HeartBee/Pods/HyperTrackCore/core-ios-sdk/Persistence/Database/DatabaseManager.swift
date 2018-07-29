//
//  DatabaseManager.swift
//  HyperTrackCore
//
//  Created by Ashish Asawa on 13/07/18.
//  Copyright © 2018 www.hypertrack.com. All rights reserved.
//

import Foundation

protocol AbstractDatabaseManager: class {
    func getDatabaseManager(_ collectionType: EventCollectionType) -> EventsFMDBDatabaseManager?
    func moveData(fromCollectionType from: EventCollectionType, to: EventCollectionType, completionHandler: @escaping BooleanCompletionHandler)
}

public final class DatabaseManager {
    struct Info {
        let name: String
        let collectionTypes: [EventCollectionType]
    }
    
    fileprivate var instances: [EventCollectionType: EventsFMDBDatabaseManager] = [:]
    fileprivate var dbManager: FMDBManager
    
    init(dbInfo info: Info) {
        dbManager = FMDBManager(withDatabaseName: info.name)
        info.collectionTypes.forEach({
            switch $0 {
            case .online:
                instances[$0] = EventsFMDBDatabaseManager(
                                    eventInfo: EventsFMDBDatabaseManager.Info(tableName: Constant.Database.TableName.onlineEvent),
                                    dbManager: dbManager)
            case .offline:
                instances[$0] = EventsFMDBDatabaseManager(
                                    eventInfo: EventsFMDBDatabaseManager.Info(tableName: Constant.Database.TableName.offlineEvent),
                                    dbManager: dbManager)
            }
        })
    }
}

extension DatabaseManager: AbstractDatabaseManager {
    func getDatabaseManager(_ collectionType: EventCollectionType) -> EventsFMDBDatabaseManager? {
        return instances[collectionType]
    }
    
    func moveData(fromCollectionType from: EventCollectionType, to: EventCollectionType, completionHandler: @escaping BooleanCompletionHandler) {
        //TODO: Selective columns insert ?
        let inserQuery = "INSERT INTO \(to.tableName()) SELECT NULL, id, type, data, recorded_at FROM \(from.tableName())"
        let deleteQuery = "DELETE from \(from.tableName())"
        let query = inserQuery + ";" + deleteQuery
        let dbResult = self.dbManager.execute(sqlStatements: query)
        completionHandler(dbResult.0)
    }
}
