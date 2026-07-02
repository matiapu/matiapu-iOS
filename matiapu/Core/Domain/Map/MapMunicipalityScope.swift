//
//  MapMunicipalityScope.swift
//  matiapu
//

import CoreLocation
import Foundation

nonisolated struct MapMunicipalityScope: Equatable, Sendable {
    let name: String
    let boundary: MunicipalityBoundary

    var bounds: MunicipalityBounds { boundary.boundingBox }
    var center: CLLocationCoordinate2D { boundary.center }

    static func == (lhs: MapMunicipalityScope, rhs: MapMunicipalityScope) -> Bool {
        lhs.name == rhs.name && lhs.boundary == rhs.boundary
    }
}

enum MapMunicipalityScopeResolver {
    @MainActor
    static func resolve(name: String) async -> MapMunicipalityScope? {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }

        if let boundary = await MunicipalityBoundaryLoader.shared.loadBoundary(municipalityName: trimmed) {
            return MapMunicipalityScope(name: trimmed, boundary: boundary)
        }

        return await fallbackScope(name: trimmed)
    }

    @MainActor
    private static func fallbackScope(name: String) async -> MapMunicipalityScope? {
        let resolver = RegionCoordinateResolver()
        guard let center = await resolver.coordinate(for: name) else { return nil }

        let radius = radiusDegrees(for: name)
        let bounds = MunicipalityBounds.square(around: center, radiusDegrees: radius)
        let ring = [
            CLLocationCoordinate2D(latitude: bounds.southWest.latitude, longitude: bounds.southWest.longitude),
            CLLocationCoordinate2D(latitude: bounds.southWest.latitude, longitude: bounds.northEast.longitude),
            CLLocationCoordinate2D(latitude: bounds.northEast.latitude, longitude: bounds.northEast.longitude),
            CLLocationCoordinate2D(latitude: bounds.northEast.latitude, longitude: bounds.southWest.longitude),
            CLLocationCoordinate2D(latitude: bounds.southWest.latitude, longitude: bounds.southWest.longitude),
        ]

        let boundary = MunicipalityBoundary(
            polygons: [MunicipalityBoundary.Polygon(exterior: ring, holes: [])]
        )

        return MapMunicipalityScope(name: name, boundary: boundary)
    }

    private static func radiusDegrees(for municipality: String) -> Double {
        if municipality.hasSuffix("区") {
            return 0.035
        }
        if municipality.hasSuffix("町") || municipality.hasSuffix("村") {
            return 0.055
        }
        return 0.045
    }
}
