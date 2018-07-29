//
//  APIClient.swift
//  core-ios-sdk
//
//  Created by Atul Manwar on 31/05/18.
//  Copyright © 2018 www.hypertrack.com. All rights reserved.
//

import Foundation

public protocol AbstractAPIClient: class {
    func makeRequest(_ endpoint: APIEndpoint) -> Task<Response>
    func cancelAllRequests()
}

public final class APIClient {
    internal var session: URLSession? = nil {
        willSet {
            session?.finishTasksAndInvalidate()
        }
    }
    fileprivate weak var config: AbstractNetworkConfig?
    fileprivate weak var logger: AbstractLogger?
    fileprivate var retryCount: Int {
        return config?.network.retryCount ?? Constant.Config.Network.retryCount
    }
    fileprivate var openRequests: [String: Request] = [:]
    fileprivate weak var tokenProvider: AuthTokenProvider?
    weak var detailsProvider: AccountAndDeviceDetailsProvider?
    
    public init(_ config: AbstractNetworkConfig, tokenProvider: AuthTokenProvider?, detailsProvider: AccountAndDeviceDetailsProvider?) {
        let configuration = URLSessionConfiguration.default
        configuration.timeoutIntervalForRequest = Constant.Config.Network.timeoutInterval
        session = URLSession(configuration: configuration)
        logger = nil
        self.config = config
        self.detailsProvider = detailsProvider
        self.tokenProvider = tokenProvider
    }
    
    public init(session: URLSession, config: AbstractNetworkConfig, logger: AbstractLogger?) {
        self.session = session
        self.logger = logger
        self.config = config
    }
}

extension APIClient: AbstractAPIClient {
    public func makeRequest(_ endpoint: APIEndpoint) -> Task<Response> {
        return getTaskForRequest(session: session, endpoint: endpoint, retryCount: retryCount, logger: logger)
            .continueWithTask(continuation: { [weak self] (task) -> Task<Response> in
                guard let `self` = self else { return task }
                if let error = task.error as? CoreError {
                    if error.type == .authorizationFailed {
                        return ReAuthorizeStep(input: Initialization.Input.ReAuthorize(tokenProvider: self.tokenProvider, apiClient: self, detailsProvider: self.detailsProvider)).execute(input: ())
                            .continueWithTask(continuation: { [weak self] (task) -> Task<Response> in
                                guard let `self` = self else { return task }
                                return self.getTaskForRequest(session: self.session, endpoint: endpoint, retryCount: self.retryCount, logger: self.logger)
                            })
                    } else if error.type == .forbidden {
                        self.tokenProvider?.status = .inactive
                        return task
                    } else {
                        return task
                    }
                } else {
                    return task
                }
            })
    }
    
    fileprivate func getTaskForRequest(session: URLSession?, endpoint: APIEndpoint, retryCount: Int, logger: AbstractLogger?) -> Task<Response> {
        let id = UUID().uuidString
        guard let request = Request(id: id, session: session, endpoint: endpoint, retryCount: retryCount, logger: logger) else {
            return Task<Response>(Response())
        }
        openRequests[id] = request
        let taskCompletionSource = TaskCompletionSource<Response>()
        request.execute { [weak self] response in
            if let error = response.error {
                taskCompletionSource.set(error: error)
            } else {
                taskCompletionSource.set(result: response)
            }
            self?.openRequests[id] = nil
        }
        return taskCompletionSource.task
    }
    
    public func cancelAllRequests() {
        guard let session = session else {
            return
        }
        
        session.getTasksWithCompletionHandler({ data, upload, download in
            for task in data {
                task.cancel()
            }
        })
    }
}
