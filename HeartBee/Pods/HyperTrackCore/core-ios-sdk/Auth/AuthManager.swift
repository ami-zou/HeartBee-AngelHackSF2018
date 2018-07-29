//
//  AuthManager.swift
//  core-ios-sdk
//
//  Created by Atul Manwar on 06/06/18.
//  Copyright © 2018 www.hypertrack.com. All rights reserved.
//

import Foundation

public struct AuthToken: Codable {
    let token: String
    
    public init() {
        token = ""
    }
    
    enum Keys: String, CodingKey {
        case token = "access_token"
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: Keys.self)
        token = (try? container.decode(String.self, forKey: .token)) ?? ""
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: Keys.self)
        try container.encode(token, forKey: .token)
    }
}

public protocol AuthTokenProvider: class {
    var authToken: AuthToken? { get set }
    var status: AuthManager.Status { get set }
}

final public class AuthManager: AuthTokenProvider {
    fileprivate weak var config: AbstractNetworkConfig?
    fileprivate weak var dataStore: AbstractReadWriteDataStore?
    fileprivate weak var serviceManager: BaseServiceManager?
    fileprivate let authTokenKey = "com.hypertrack.sdk.core.auth.token"
    fileprivate let statusKey = "com.hypertrack.sdk.core.auth.status"
    
    public var authToken: AuthToken? {
        didSet {
            guard let authToken = authToken else {
                dataStore?.removeObject(forKey: authTokenKey)
                return
            }
            guard oldValue?.token != authToken.token else {
                return
            }
            dataStore?.set(try? JSONEncoder.hyperTrackEncoder.encode(authToken), forKey: authTokenKey)
        }
    }
    
    public var status: AuthManager.Status = .active {
        didSet {
            if status == .inactive {
                serviceManager?.stopAllServices()
            }
        }
    }

    public init(config: AbstractNetworkConfig?, dataStore: AbstractReadWriteDataStore?, serviceManager: BaseServiceManager?) {
        self.config = config
        self.dataStore = dataStore
        self.serviceManager = serviceManager
        if let data = dataStore?.data(forKey: authTokenKey) {
            authToken = try? JSONDecoder.hyperTrackDecoder.decode(AuthToken.self, from: data)
        }
        if let data = dataStore?.data(forKey: statusKey) {
            do {
                status = try JSONDecoder.hyperTrackDecoder.decode(Status.self, from: data)
            } catch {
                //Expecting this to fail only on first launch
                status = .active
            }
        }
    }
    
    public enum Status: Int, Codable {
        case active = 0
        case inactive
    }
}
