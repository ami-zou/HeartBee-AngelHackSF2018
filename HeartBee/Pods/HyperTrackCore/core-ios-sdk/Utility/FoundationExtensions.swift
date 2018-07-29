//
//  FoundationExtensions.swift
//  core-ios-sdk
//
//  Created by Atul Manwar on 31/05/18.
//  Copyright © 2018 www.hypertrack.com. All rights reserved.
//

import Foundation
import CoreLocation

extension DateFormatter {
    static let iso8601Full: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZZZZZ"
        formatter.calendar = Calendar(identifier: .iso8601)
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        formatter.locale = Locale(identifier: "en_US_POSIX")
        return formatter
    }()
}

extension JSONDecoder {
    public static var hyperTrackDecoder: JSONDecoder {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .formatted(DateFormatter.iso8601Full)
        return decoder
    }
}

extension JSONEncoder {
    public static var hyperTrackEncoder: JSONEncoder {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .formatted(DateFormatter.iso8601Full)
        return encoder
    }
}


extension Double {
    var degrees: Double {
        return self * 180.0 / .pi
    }
    
    var radians: Double {
        return self * .pi / 180.0
    }
}

extension CLLocation {
    func getBearing(fromPrevious previous: CLLocation) -> Double {
        let previousLatRadians = previous.coordinate.latitude.radians
        let previousLngRadians = previous.coordinate.longitude.radians
        
        let currentLatRadians = coordinate.latitude.radians
        let currentLngRadians = coordinate.longitude.radians
        
        let diffLng = currentLngRadians - previousLngRadians
        
        let yCord = sin(diffLng) * cos(currentLatRadians)
        let xCord = cos(previousLatRadians) * sin(currentLatRadians) - sin(previousLatRadians) * cos(currentLatRadians) * cos(diffLng)
        
        return atan2(yCord, xCord).degrees
    }
}
