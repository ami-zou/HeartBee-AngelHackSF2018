//
//  Response.swift
//  core-ios-sdk
//
//  Created by Atul Manwar on 31/05/18.
//  Copyright © 2018 www.hypertrack.com. All rights reserved.
//

import Foundation

let emptyDataStatusCodes: Set<Int> = [204, 205]

public enum Result<Value> {
    case success(Value)
    case failure(CoreError)
    
    /// Returns `true` if the result is a success, `false` otherwise.
    public var isSuccess: Bool {
        switch self {
        case .success:
            return true
        case .failure:
            return false
        }
    }
    
    /// Returns `true` if the result is a failure, `false` otherwise.
    public var isFailure: Bool {
        return !isSuccess
    }
    
    /// Returns the associated value if the result is a success, `nil` otherwise.
    public var value: Any? {
        switch self {
        case .success(let value):
            return value
        case .failure:
            return nil
        }
    }
    
    /// Returns the associated error value if the result is a failure, `nil` otherwise.
    public var error: CoreError? {
        switch self {
        case .success:
            return nil
        case .failure(let error):
            return error
        }
    }
}


public final class Response {
    /// String representing JSON response data.
    public var data: Data?
    
    /// HTTP status code of response.
    public var statusCode: Int
    
    /// Response metadata.
    public var response: HTTPURLResponse?
    
    /// Error representing an optional error.
    public var error: CoreError?
    
    public let result: Result<Data>
    
    /**
     Initialize a Response object.
     
     - parameter data:     Data returned from server.
     - parameter response: Provides response metadata, such as HTTP headers and status code.
     - parameter error:    Indicates why the request failed, or nil if the request was successful.
     */
    public init(data: Data?, statusCode: Int, response: HTTPURLResponse?, error: CoreError?) {
        self.data = data
        self.response = response
        self.statusCode = statusCode
        self.error = error
        if error != nil {
            self.result = .failure(error!)
        } else if let response = response, emptyDataStatusCodes.contains(response.statusCode) {
            self.result = .success(Data())
        } else if let data = data {
            self.result = .success(data)
        } else {
            self.result = .failure(CoreError(.parsingError))
        }
    }
    
    public init() {
        data = nil
        response = nil
        statusCode = 400
        error = nil
        result = Result.failure(CoreError(.badRequest))
    }
    
    /**
     - returns: string representation of JSON data.
     */
    func toJSONString() -> String {
        guard let data = data else {
            return ""
        }
        return String(data: data, encoding: String.Encoding.utf8)!
    }
}
