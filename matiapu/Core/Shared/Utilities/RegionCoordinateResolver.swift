//
//  RegionCoordinateResolver.swift
//  matiapu
//

import CoreLocation
import Foundation
import MapKit

@MainActor
final class RegionCoordinateResolver {
    private var cache: [String: CLLocationCoordinate2D] = [:]

    func coordinate(for area: String) async -> CLLocationCoordinate2D? {
        let trimmed = area.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }

        if let cached = cache[trimmed] {
            return cached
        }

        if let known = Self.knownCoordinates[trimmed] {
            cache[trimmed] = known
            return known
        }

        let query = "\(trimmed), 日本"
        guard let request = MKGeocodingRequest(addressString: query) else {
            return nil
        }

        do {
            let mapItems = try await request.mapItems
            guard let coordinate = mapItems.first?.location.coordinate else {
                return nil
            }
            cache[trimmed] = coordinate
            return coordinate
        } catch {
            return nil
        }
    }

    private static let knownCoordinates: [String: CLLocationCoordinate2D] = [
        "新宿区": CLLocationCoordinate2D(latitude: 35.6939, longitude: 139.7036),
        "渋谷区": CLLocationCoordinate2D(latitude: 35.6640, longitude: 139.6982),
        "千代田区": CLLocationCoordinate2D(latitude: 35.6940, longitude: 139.7536),
        "港区": CLLocationCoordinate2D(latitude: 35.6581, longitude: 139.7514),
        "東京都": CLLocationCoordinate2D(latitude: 35.6895, longitude: 139.6917),
        "大阪府": CLLocationCoordinate2D(latitude: 34.6937, longitude: 135.5023),
        "北海道": CLLocationCoordinate2D(latitude: 43.0642, longitude: 141.3469),
    ]
}
