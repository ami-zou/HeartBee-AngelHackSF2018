//
//  PrivacyDataTypes.swift
//  core-ios-sdk
//
//  Created by Ashish Asawa on 11/06/18.
//  Copyright © 2018 www.hypertrack.com. All rights reserved.
//

import Foundation

// Following code copied from Apple Sample Project PrivacyPrompts

/**
 A type with a localized string that is appropiate to display in UI.
 */
protocol Localizable {
    func localizedValue() -> String
}

/**
 An enumeration of all the different private data access levels. Not every access level is applicable to every `PrivacyDataType`.
 */
enum PrivateDataAccessLevel: String, Localizable {
    
    case unavailable            = "UNAVAILABLE"                 // hardware level
    case undetermined           = "UNDETERMINED"                // permission not requested, or initial state
    case restricted             = "RESTRICTED"                  // os level disabled
    case denied                 = "DENIED"                      // user has not granted it
    case granted                = "GRANTED"                     // user has authorized it
    case grantedWhenInUse       = "LOCATION_WHEN_IN_USE"        // user has authorized when in use (location specific)
    case grantedAlways          = "LOCATION_ALWAYS"             // user has authorized always (location specific)
    
    func localizedValue() -> String {
        return NSLocalizedString(self.rawValue, comment: "Access level label for \(self.rawValue)")
    }
}

/**
 A struct containing the results of prompting the user for access to a subset of their private data.
 */
struct PrivateDataRequestAccessResult: Localizable {
    let accessLevel: PrivateDataAccessLevel
    let error: NSError?
    let errorMessageKey: String?
    
    init(_ accessLevel: PrivateDataAccessLevel, error: NSError? = nil, errorMessageKey: String? = nil) {
        self.accessLevel = accessLevel
        self.error = error
        self.errorMessageKey = errorMessageKey
    }
    
    func localizedValue() -> String {
        var message = accessLevel.localizedValue()
        
        if let errorMessageKey = errorMessageKey, let error = error {
            let localizedErrorFormatString = NSLocalizedString(errorMessageKey, comment: "")
            let errorDescription = String(format: localizedErrorFormatString, error.code, error.localizedDescription)
            message += " \(errorDescription)"
        }
        
        return message
    }
}
