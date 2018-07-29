//
//  Request.swift
//  core-ios-sdk
//
//  Created by Atul Manwar on 31/05/18.
//  Copyright © 2018 www.hypertrack.com. All rights reserved.
//

import Foundation

/// Class to create and execute NSURLRequests.
public final class Request {
    let id: String
    fileprivate weak var session: URLSession?
    let endpoint: APIEndpoint
    private(set) public var urlRequest: URLRequest
    fileprivate weak var logger: AbstractLogger?
    fileprivate var numberOfRetries: Int
    let maxRetryCount: Int
    
    public init?(id: String, session: URLSession?, endpoint: APIEndpoint, retryCount: Int, logger: AbstractLogger?) {
        self.id = id
        urlRequest = URLRequest(url: endpoint.url)
        urlRequest.httpMethod = endpoint.method.rawValue
        urlRequest.httpBody = endpoint.body
        
        self.session = session
        self.endpoint = endpoint
        self.logger = logger
        self.numberOfRetries = 0
        self.maxRetryCount = retryCount
    }
    
    func getNextTime(error: CoreError, counter: Int, maxRetryCount: Int, endpoint: APIEndpoint) -> Double? {
        guard !error.isServerError else { return nil }
        let intervals = endpoint.retryIntervals
        if counter < intervals.count && counter >= 0 && counter < maxRetryCount {
            return intervals[counter]
        } else {
            return nil
        }
    }
    
    /**
     Adds HTTP Headers to the request.
     */
    private func addHeaders() {
        //TODO: add proper headers
//        urlRequest.setValue("gzip, deflate", forHTTPHeaderField: "Accept-Encoding")
        for (header,value) in endpoint.headers {
            urlRequest.setValue(value, forHTTPHeaderField: header)
        }
    }
    
    /**
     Prepares the NSURLRequest by adding necessary fields.
     */
    public func prepare() {
        addHeaders()
    }
    
    /**
     Performs all steps to execute request (construct URL, add headers, etc).
     
     - parameter completion: completion handler for returned Response.
     */
    public func execute(_ completion: @escaping (_ response: Response) -> Void) {
        guard let session = session else {
            return
        }
        
        addHeaders()
        let task = session.dataTask(with: urlRequest, completionHandler: { [weak self] (data, response, error) in
            guard let `self` = self else { return }
            let httpResponse: HTTPURLResponse? = response as? HTTPURLResponse
            var statusCode: Int = 0
            var htError: CoreError?
            
            // Handle HTTP errors.
            errorCheck: if httpResponse != nil {
                statusCode = httpResponse!.statusCode
                
                if statusCode <= 299 {
                    break errorCheck
                }
                htError = CoreError(code: statusCode)
                self.logger?.logError(htError?.errorMessage ?? "", context: Constant.Context.network)
            }
            
            // Any other errors.
            if (response == nil && !emptyDataStatusCodes.contains(statusCode)) || error != nil {
                if let errorCode = error?._code {
                    htError = CoreError(code: errorCode)
                } else {
                    htError = CoreError(.unknown)
                }
                self.logger?.logError(htError?.errorMessage ?? "", context: Constant.Context.network)
            }
            if let error = htError, let delay = self.getNextTime(error: error, counter: self.numberOfRetries, maxRetryCount: self.maxRetryCount, endpoint: self.endpoint), delay > 0 {
                self.numberOfRetries += 1
                DispatchQueue.global(qos: DispatchQoS.QoSClass.default).asyncAfter(deadline: .now() + delay, execute: { [weak self] in
                    self?.execute(completion)
                })
            } else {
                let response = Response(data: data, statusCode: statusCode, response: httpResponse, error: htError)
                completion(response)
            }
        })
        task.resume()
    }
}
