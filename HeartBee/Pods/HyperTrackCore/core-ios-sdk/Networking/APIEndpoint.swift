//
//  APIEndpoint.swift
//  core-ios-sdk
//
//  Created by Atul Manwar on 31/05/18.
//  Copyright © 2018 www.hypertrack.com. All rights reserved.
//

import Foundation

public enum HTTPMethod: String {
    case get    = "GET"
    case post   = "POST"
    case put    = "PUT"
    case patch  = "PATCH"
    case delete = "DELETE"
    case head   = "HEAD"
}

public protocol APIEndpoint {
    var body: Data? { get }
    var headers: [String: String] { get }
    var host: String { get}
    var method: HTTPMethod { get }
    var path: String { get }
    var params: Any? { get }
    var encoding: ParamEncoding { get }
    var retryIntervals: [Double] { get }
}

public extension APIEndpoint {
    var body: Data? {
        return nil
    }
    
    var params: Any? {
        return nil
    }
    
    var headers: [String: String] {
        return [:]
    }
    
    var baseURL: String {
        return host
    }
    
    var url: URL {
        var components = URLComponents(string: baseURL)
        components?.path = path
        if method == .get, let params = params as? Payload {
            components?.queryItems = params.map({ return URLQueryItem(name: $0.key, value: ($0.value as? String) )})
        }
        guard let url = components?.url else {
            preconditionFailure("Could not generate URL from endpoint object. ")
        }
        return url
    }
    
    /**
     Helper function to build array of NSURLQueryItems. A key-value pair with an empty string value is ignored.
     
     - parameter queries: tuples of key-value pairs
     - returns: an array of URLQueryItems
     */
    func queryBuilder(_ queries: (name: String, value: String)...) -> [URLQueryItem] {
        var queryItems = [URLQueryItem]()
        for query in queries {
            if query.name.isEmpty || query.value.isEmpty {
                continue
            }
            queryItems.append(URLQueryItem(name: query.name, value: query.value))
        }
        return queryItems
    }
}
