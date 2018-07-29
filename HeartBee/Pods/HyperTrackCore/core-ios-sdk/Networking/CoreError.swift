//
//  CoreError.swift
//  core-ios-sdk
//
//  Created by Atul Manwar on 31/05/18.
//  Copyright © 2018 www.hypertrack.com. All rights reserved.
//

import Foundation

/**
 The HyperTrack Error object. Contains an error type.
 */
@objc(HTCoreError) public final class CoreError: NSObject, Error {
    
    /**
     Enum for various error types
     */
    public let type: ErrorType
    public var errorCode: Int {
        return type.rawValue
    }
    public let errorMessage: String
    public var displayErrorMessage: String {
        return type.toString()
    }
    
    public init(code: Int) {
        type = ErrorType(rawValue: code)
        errorMessage = type.toString()
    }
    
    init(_ type: ErrorType) {
        self.type = type
        errorMessage = type.toString()
    }
    
    init(_ type: ErrorType, responseData: Data?) {
        self.type = type
        if let data = responseData, let errorMessage =  String(data: data, encoding: .utf8) {
            self.errorMessage = errorMessage
        } else {
            self.errorMessage = ""
        }
    }
    
    static var `default`: CoreError {
        return CoreError(.unknown)
    }
    
    internal func toDict() -> [String: Any] {
        return [
            "code": self.errorCode,
            "message": self.errorMessage
            ]
    }
    
    public func toJson() -> String {
        let dict = self.toDict()
        do {
            let jsonData = try JSONSerialization.data(withJSONObject: dict)
            let jsonString = String(data: jsonData, encoding: String.Encoding.utf8)
            return jsonString ?? ""
        } catch {
            //Add Logger
            return ""
        }
    }
    
    public var isServerError: Bool {
        switch type {
        case .internalServerError:
            return true
        default:
            return false
        }
    }
}

public enum ErrorType: Int {
    case badRequest                         = 400
    case authorizationFailed                = 401
    case forbidden                          = 403
    case internalServerError                = 500
    case urlErrorUnknown                    = -998
    case urlErrorCancelled                  = -999
    case urlErrorBadURL                     = -1000
    case urlErrorTimedOut                   = -1001
    case urlErrorUnsupportedURL             = -1002
    case urlErrorCannotFindHost             = -1003
    case urlErrorCannotConnectToHost        = -1004
    case urlErrorNetworkConnectionLost      = -1005
    case urlErrorNotConnectedToInternet     = -1009
    case parsingError                       = 98765
    case locationPermissionsDenied
    case activityPermissionsDenied
    case serviceAlreadyRunning
    case serviceAlreadyStopped
    case networkDisconnected
    case databaseReadFailed
    case databaseWriteFailed
    case sensorToDataMappingFailed
    case deviceIdBlank
    case emptyResult
    case unknownService
    case sdkNotInitialized
    case unknown
    
    public init(rawValue: Int) {
        switch rawValue {
        case 400:
            self = .badRequest
        case 401:
            self = .authorizationFailed
        case 403:
            self = .forbidden
        case 500..<599:
            self = .internalServerError
        case -998:
            self = .urlErrorUnknown
        case -999:
            self = .urlErrorCancelled
        case -1000:
            self = .urlErrorBadURL
        case -1001:
            self = .urlErrorTimedOut
        case -1002:
            self = .urlErrorUnsupportedURL
        case -1003:
            self = .urlErrorCannotFindHost
        case -1004:
            self = .urlErrorCannotConnectToHost
        case -1005:
            self = .urlErrorNetworkConnectionLost
        case -1009:
            self = .urlErrorNotConnectedToInternet
        case 98765:
            self = .parsingError
        case 98766:
            self = .locationPermissionsDenied
        case 98767:
            self = .activityPermissionsDenied
        case 98769:
            self = .serviceAlreadyRunning
        case 98770:
            self = .serviceAlreadyStopped
        case 98771:
            self = .networkDisconnected
        case 98772:
            self = .databaseReadFailed
        case 98773:
            self = .databaseWriteFailed
        case 98774:
            self = .sensorToDataMappingFailed
        case 98775:
            self = .deviceIdBlank
        case 98776:
            self = .emptyResult
        case 98777:
            self = .unknownService
        default:
            self = .unknown
        }
    }

    public func toString() -> String {
        switch self {
        case .urlErrorUnknown:
            return "Unable to connect to the internet"
        case .urlErrorCancelled:
            return "The connection failed because the user cancelled required authentication"
        case .urlErrorBadURL:
            return "Bad URL"
        case .urlErrorTimedOut:
            return "The connection timed out"
        case .urlErrorUnsupportedURL:
            return "URL not supported"
        case .urlErrorCannotFindHost:
            return "The connection failed because the host could not be found"
        case .urlErrorCannotConnectToHost:
            return "The connection failed because a connection cannot be made to the host"
        case .urlErrorNetworkConnectionLost:
            return "The connection failed because the network connection was lost"
        case .urlErrorNotConnectedToInternet:
            return "The connection failed because the device is not connected to the internet"
        case .badRequest:
            return "Bad Request"
        case .authorizationFailed:
            return "Authorization Failed"
        case .forbidden:
            return "Access has been revoked. Please contact HyperTrack for more information."
        case .internalServerError:
            return "Internal Server Error"
        case .parsingError:
            return "JSON parsing error"
        case .locationPermissionsDenied:
            return "Access to Location services has not been authorized"
        case .activityPermissionsDenied:
            return "Access to Activity services has not been authorized"
        case .serviceAlreadyRunning:
            return "Attempted to start a service which was already running"
        case .serviceAlreadyStopped:
            return "Attempted to stop a service which was already stopped"
        case .networkDisconnected:
            return "Network disconnected"
        case .databaseReadFailed:
            return "Failed to read data from database"
        case .databaseWriteFailed:
            return "Failed to write data to database"
        case .sensorToDataMappingFailed:
            return "Failed to map sensor data to Event object"
        case .deviceIdBlank:
            return "DeviceId is blank"
        case .emptyResult:
            return "The result of this operation is empty."
        case .unknownService:
            return "Attempted to start access unknown service"
        case .sdkNotInitialized:
            return "Attempt to start tracking, before sdk initialization is completed"
        case .unknown:
            return "Something went wrong"
        }
    }
}
