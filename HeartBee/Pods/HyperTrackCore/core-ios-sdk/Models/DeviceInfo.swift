//
//  DeviceInfo.swift
//  HyperTrackCoreSDK
//
//  Created by Ashish Asawa on 19/06/18.
//

import Foundation
import CoreTelephony

public protocol DeviceDataProtocol: class {
    func getDeviceData() -> DeviceInfo
}

public final class DeviceInfo: JSONDictProtocol {

    let deviceId:           String
    let timeZone:           String
    let networkOperator:    String                  // Airtel, verizon etc
    let deviceManufacturer: String
    let deviceHardware:     String
    let osName:             String
    let osVersion:          String
    let appPackageName:     String
    let appVersion:         String
    let sdkVersion:         String
    let recordedAt:         Date
    let hasPlayServices:    String
    
    init(deviceId:          String,
         timeZone:          String,
         networkOperator:   String,
         manufacturer:      String,
         deviceHardware:    String,
         osName:            String,
         osVersion:         String,
         appPackageName:    String,
         appVersion:        String,
         sdkVersion:        String,
         recordedAt:        Date
         ) {
        self.deviceId            = deviceId
        self.timeZone            = timeZone
        self.networkOperator     = networkOperator
        self.deviceManufacturer  = manufacturer
        self.deviceHardware      = deviceHardware
        self.osName              = osName
        self.osVersion           = osVersion
        self.appPackageName      = appPackageName
        self.appVersion          = appVersion
        self.sdkVersion          = sdkVersion
        self.recordedAt          = recordedAt
        self.hasPlayServices     = "false"
    }
    
    
    // MARK: JSON Result Protocol Method
    
    func jsonDict() -> JSONResult {
        var dict: [String : Any] = [:]
        dict[Constant.ServerKeys.DeviceInfo.deviceId]                   = deviceId
        dict[Constant.ServerKeys.DeviceInfo.timeZone]                   = timeZone
        dict[Constant.ServerKeys.DeviceInfo.networkOperator]            = networkOperator
        dict[Constant.ServerKeys.DeviceInfo.deviceManufacturer]         = deviceManufacturer
        dict[Constant.ServerKeys.DeviceInfo.deviceHardware]             = deviceHardware
        dict[Constant.ServerKeys.DeviceInfo.osName]                     = osName
        dict[Constant.ServerKeys.DeviceInfo.osVersion]                  = osVersion
        dict[Constant.ServerKeys.DeviceInfo.appPackageName]             = appPackageName
        dict[Constant.ServerKeys.DeviceInfo.appVersion]                 = appVersion
        dict[Constant.ServerKeys.DeviceInfo.sdkVersion]                 = sdkVersion
        dict[Constant.ServerKeys.DeviceInfo.hasPlayServices]            = hasPlayServices
        dict[Constant.ServerKeys.DeviceInfo.recordedAt]                 = DateFormatter.iso8601Full.string(from: recordedAt)
        return JSONResult.success(dict)
    }
    
}
