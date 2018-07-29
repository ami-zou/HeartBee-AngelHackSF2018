//
//  FMDBManager.swift
//  core-ios-sdk
//
//  Created by Ashish Asawa on 07/06/18.
//  Copyright © 2018 www.hypertrack.com. All rights reserved.
//

import Foundation

typealias FmdbQueryResult = (Bool, String?)
typealias FmdbSelectQueryResult = (FMResultSet?, String?)

final class FMDBManager {
    
    var pathToDatabase: String!
    
    var databaseQueue: FMDatabaseQueue!
    
    init(withDatabaseName name: String) {
        let documentsDirectory = (NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0] as NSString) as String
        pathToDatabase = documentsDirectory.appending("/\(name)")
        databaseQueue  = FMDatabaseQueue(path: pathToDatabase)
    }
    
    // single sql statement, create table, insert, delete, update records
    func execute(updatesForQuery query: String, values: [Any]?) -> (FmdbQueryResult) {
        var result: FmdbQueryResult = (false, nil)
        databaseQueue.inTransaction { (db, rollback) in
            do {
                try db.executeUpdate(query, values: values)
                result.0 = true
            } catch {
                // TODO: Logger Integration
                rollback.pointee = true
                debugPrint(error.localizedDescription)
                result.1 = error.localizedDescription
            }
        }
        return result
    }
    
    // fetch records
    func execute(selectQuery query: String, values:[Any]?) -> (FmdbSelectQueryResult) {
        var result:(FMResultSet?, String?) = (nil, nil)
        databaseQueue.inTransaction { (db, rollback) in
            do {
                let results = try db.executeQuery(query, values: values)
                result.0 = results
            } catch {
                result.1 = error.localizedDescription
                rollback.pointee = true
            }
        }
        return result
    }
    
    // multiple statements, create, delete, update
    func execute(sqlStatements statements: String ) -> (Bool, String?) {
        var result:(Bool, String?) = (false, nil)
        databaseQueue.inTransaction { (db, rollback) in
            if !db.executeStatements(statements) {
                //TODO: Logging
                debugPrint("Failed to perform \(statements) into the database.")
                debugPrint(db.lastError(), db.lastErrorMessage())
                rollback.initialize(to: true)
                result.1 = db.lastErrorMessage()
            } else {
                result.0 = true
            }
        }
        return result
    }
    
}

