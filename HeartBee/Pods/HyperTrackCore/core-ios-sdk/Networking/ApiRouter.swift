//
//  ApiRouter.swift
//  core-ios-sdk
//
//  Created by Atul Manwar on 31/05/18.
//  Copyright © 2018 www.hypertrack.com. All rights reserved.
//

import Foundation

public typealias Payload  = [String: Any]
public typealias DeviceId = String
public typealias TimeDiff = Int

enum ApiRouter {
    case sendEvent([Payload])
    case heartbeatPing(DeviceId, TimeDiff)
    case deviceRegister(Payload)
    case getToken(deviceId: String)
}

public enum ParamEncoding: Int {
    case url
    case json
    case gzip
}

extension ApiRouter: APIEndpoint {
    static var baseUrlString: String { return Provider.configManager.config.network.host }
    //TODO: from config
    static var heartbeatBaseUrlString = "https://api.hypertrack.com"

    var host: String {
        switch self {
        case .heartbeatPing, .deviceRegister, .getToken:
            return ApiRouter.heartbeatBaseUrlString
        default:
            return ApiRouter.baseUrlString
        }
    }
    
    private var eventsPath: String {
        return "/events"
    }
    
    private var heartbeatPing: String {
        return "/heartbeat/v1/ping"
    }
    
    private var heartbeatRegister: String {
        return "/heartbeat/v1/register"
    }
    
    private var authenticate: String {
        return "/auth/v1"
    }
    
    var path: String {
        switch self {
        case .sendEvent:
            return "\(eventsPath)"
        case .heartbeatPing(let result):
            return "\(heartbeatPing)" + "/" + result.0
        case .deviceRegister:
            return "\(heartbeatRegister)"
        case .getToken:
            return "\(authenticate)/authenticate"
        }
    }
    
    var params: Any? {
        switch self {
        case .sendEvent(let array):
            return array
        case .heartbeatPing:
            return [:]
        case .deviceRegister(let data):
            return data
        case .getToken(let deviceId):
            return ["device_id": deviceId,
                    "scope":"generation"]
        }
    }
    
    var body: Data? {
        guard let params = params, encoding != .url else { return nil }
        switch encoding {
        case .json:
            do {
                 return try JSONSerialization.data(withJSONObject: params, options: JSONSerialization.WritingOptions(rawValue: 0))
            } catch {
                return nil
            }
        default:
            return nil
        }
    }
    
    var encoding: ParamEncoding {
        switch self {
        case .sendEvent, .deviceRegister, .getToken:
            return .json
        default:
            return .url
        }
    }
    
    var method: HTTPMethod {
        switch self {
        case .sendEvent, .getToken, .deviceRegister:
            return .post
        case .heartbeatPing:
            return .head
        }
    }

    var headers: [String: String] {
        switch self {
        case .heartbeatPing(let result):
            return [
                "Content-Type": "application/json",
                "Timezone": TimeZone.current.identifier,
                Constant.ServerKeys.Heartbeat.lastPingTime: String(result.1),
                "Authorization": "token \(Provider.authManager.authToken?.token ?? "")"
            ]
        case .getToken:
            return [
                "Content-Type": "application/json",
                "Timezone": TimeZone.current.identifier,
                "Authorization": "token \(Provider.appState.getPublishableKey())"
            ]
        default:
            return [
                "Content-Type": "application/json",
                "Timezone": TimeZone.current.identifier,
                "Authorization": "token \(Provider.authManager.authToken?.token ?? "")"
            ]
        }
    }
    
    var retryIntervals: [Double] {
        switch self {
        case .heartbeatPing:
            return []
        default:
            return [4, 9, 16]
        }
    }
}
