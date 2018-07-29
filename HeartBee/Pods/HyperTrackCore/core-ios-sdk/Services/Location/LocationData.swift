//
//  LocationData.swift
//  core-ios-sdk
//
//  Created by Atul Manwar on 07/06/18.
//  Copyright © 2018 www.hypertrack.com. All rights reserved.
//

import Foundation
import CoreLocation

struct LocationServiceData: AbstractServiceData, Codable {
    let id: String
    let data: LocationData
    let recordedAt: Date
    let type: String = EventType.locationChange.rawValue
    
    init(id: String, data: LocationData, recordedAt: Date) {
        self.id = id
        self.data = data
        self.recordedAt = recordedAt
    }
    
    static func getData(_ locations: [CLLocation]) -> [LocationServiceData] {
        var array: [LocationServiceData] = []
        locations.enumerated().forEach({
            var data: LocationData!
            if $0.offset == 0 {
                data = LocationData($0.element)
            } else {
                data = LocationData($0.element, bearing: $0.element.getBearing(fromPrevious: locations[$0.offset - 1]))
            }
            array.append(LocationServiceData(id: UUID().uuidString, data: data, recordedAt: data.timestamp))
        })
        return array
    }
    
    func getType() -> EventType {
        return EventType.locationChange
    }
    
    func getId() -> String {
        return id
    }
    
    func getRecordedAt() -> Date {
        return recordedAt
    }
    
    func getJSONdata() -> String {
        //TODO: handle throw from here
        do {
            return try String(data: JSONEncoder.hyperTrackEncoder.encode(data), encoding: .utf8)!
        } catch {
            return ""
        }
    }
    
    enum Keys: String, CodingKey {
        case id = "id"
        case deviceID = "device_id"
        case data = "data"
        case recordedAt = "recorded_at"
        case type = "type"
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: Keys.self)
        id = try container.decode(String.self, forKey: .id)
        data = try container.decode(LocationData.self, forKey: .data)
        recordedAt = try container.decode(Date.self, forKey: .recordedAt)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: Keys.self)
        try container.encode(id, forKey: .id)
        try container.encode(data, forKey: .data)
        try container.encode(recordedAt, forKey: .recordedAt)
        try container.encode(type, forKey: .type)
    }
}

struct LocationData: Codable {
    let location: GeoJson
    let speed: Double
    let altitude: Double
    let bearing: Double
    let timestamp: Date
    
    init(_ location: CLLocation) {
        self.init(location, bearing: 0)
    }
    
    init(_ location: CLLocation, bearing: Double) {
        self.location = GeoJson(type: "Point", coordinates: location.coordinate)
        speed = location.speed
        altitude = location.altitude
        timestamp = location.timestamp
        self.bearing = bearing
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: Keys.self)
        location = try container.decode(GeoJson.self, forKey: .location)
        speed = try container.decode(Double.self, forKey: .speed)
        bearing = try container.decode(Double.self, forKey: .bearing)
        altitude = try container.decode(Double.self, forKey: .altitude)
        timestamp = try container.decode(Date.self, forKey: .timestamp)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: Keys.self)
        try container.encode(location, forKey: .location)
        try container.encode(speed, forKey: .speed)
        try container.encode(bearing, forKey: .bearing)
        try container.encode(altitude, forKey: .altitude)
        try container.encode(timestamp, forKey: .timestamp)
    }
    
    enum Keys: String, CodingKey {
        case location = "location"
        case speed = "speed"
        case altitude = "altitude"
        case bearing = "bearing"
        case timestamp = "recorded_at"
    }
    
    struct GeoJson: Codable {
        let type: String
        let coordinates: [Double]
        
        init(type: String, lat: Double, lng: Double) {
            self.type = type
            coordinates = [lng, lat]
        }
        
        init(type: String, coordinates: CLLocationCoordinate2D) {
            self.type = type
            self.coordinates = [coordinates.longitude, coordinates.latitude]
        }
        
        enum Keys: String, CodingKey {
            case type = "type"
            case coordinates = "coordinates"
        }
        
        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: Keys.self)
            type = try container.decode(String.self, forKey: .type)
            coordinates = try container.decode([Double].self, forKey: .coordinates)
        }
        
        func encode(to encoder: Encoder) throws {
            var container = encoder.container(keyedBy: Keys.self)
            try container.encode(type, forKey: .type)
            try container.encode(coordinates, forKey: .coordinates)
        }
    }
}
