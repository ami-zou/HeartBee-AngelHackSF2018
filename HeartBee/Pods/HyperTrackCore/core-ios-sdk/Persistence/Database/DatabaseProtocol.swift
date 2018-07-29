//
//  DatabaseProtocol.swift
//  core-ios-sdk
//
//  Created by Ashish Asawa on 07/06/18.
//  Copyright © 2018 www.hypertrack.com. All rights reserved.
//

import Foundation

enum DataBaseResult<Model> {
    case success(Model)
    case failure(String)
}

protocol AbstractDatabaseInfo {
    func tableName() -> String
}

protocol AbstractDatabaseProtocol {
    associatedtype T
    func insert(items:  [T],   result: @escaping (DataBaseResult<[T]>) -> Void)
    func delete(items:  [T],   result: @escaping (DataBaseResult<[T]>) -> Void)
    func fetch( count:  UInt,  result: @escaping (DataBaseResult<[T]>) -> Void)
    //TODO: Generic Return
    func deleteAll(result: @escaping (_ status: Bool) -> Void)
    //TODO: More methods
    /*
     - update
     - clean
     - multiple delete
     - fetch all
     */
}
