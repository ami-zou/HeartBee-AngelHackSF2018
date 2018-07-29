//
//  Event.swift
//  core-ios-sdk
//
//  Created by Ashish Asawa on 11/06/18.
//  Copyright © 2018 www.hypertrack.com. All rights reserved.
//

import Foundation

enum JSONResult {
    case success([String: Any])
    case failure(String)
}

protocol JSONDictProtocol {
    func jsonDict() -> JSONResult
}

struct Event: JSONDictProtocol {
    
    let type:          EventType       // type, activity.changed, location.changed etc
    let data:          String          // stringified json data
    let id:            String          // unique id
    let recordedAt:    String          // saved in string, since in db we can't save directly in date format
    
    func jsonDict() -> JSONResult {
        var dict: [String : Any] = [:]
        //TODO: device_id insertion
        if let jsonData = data.data(using: .utf8) {
            do {
                if let  jsonDict = try JSONSerialization.jsonObject(with: jsonData) as? Dictionary<String, Any> {
                    dict[Constant.ServerKeys.Event.data] = jsonDict
                } else {
                    return JSONResult.failure("Bad Json")
                }
            } catch let error as NSError {
                return JSONResult.failure(error.localizedDescription)
            }
        } else {
            return JSONResult.failure("Cannot create data")
        }
        dict[Constant.ServerKeys.Event.id]           = id
        dict[Constant.ServerKeys.Event.type]         = type.rawValue
        dict[Constant.ServerKeys.Event.recordedAt]   = recordedAt
        return JSONResult.success(dict)
    }

}
