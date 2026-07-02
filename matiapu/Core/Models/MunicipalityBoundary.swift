//
//  MunicipalityBoundary.swift
//  matiapu
//

import CoreLocation
import Foundation

nonisolated struct MunicipalityBoundary: Equatable, Sendable {
    struct Polygon: Sendable {
        let exterior: [CLLocationCoordinate2D]
        let holes: [[CLLocationCoordinate2D]]
    }

    let polygons: [Polygon]

    var boundingBox: MunicipalityBounds {
        let latitudes = polygons.flatMap(\.exterior).map(\.latitude)
        let longitudes = polygons.flatMap(\.exterior).map(\.longitude)
        guard
            let minLat = latitudes.min(),
            let maxLat = latitudes.max(),
            let minLng = longitudes.min(),
            let maxLng = longitudes.max()
        else {
            return MunicipalityBounds(
                southWest: CLLocationCoordinate2D(latitude: 0, longitude: 0),
                northEast: CLLocationCoordinate2D(latitude: 0, longitude: 0)
            )
        }

        return MunicipalityBounds(
            southWest: CLLocationCoordinate2D(latitude: minLat, longitude: minLng),
            northEast: CLLocationCoordinate2D(latitude: maxLat, longitude: maxLng)
        )
    }

    var center: CLLocationCoordinate2D { boundingBox.center }

    func contains(_ coordinate: CLLocationCoordinate2D) -> Bool {
        polygons.contains { polygon in
            pointInPolygon(coordinate, polygon: polygon.exterior)
                && !polygon.holes.contains { pointInPolygon(coordinate, polygon: $0) }
        }
    }

    func simplified(maxPointsPerRing: Int = 320) -> MunicipalityBoundary {
        MunicipalityBoundary(
            polygons: polygons.map { polygon in
                Polygon(
                    exterior: Self.decimate(polygon.exterior, maxPoints: maxPointsPerRing),
                    holes: polygon.holes.map { Self.decimate($0, maxPoints: maxPointsPerRing) }
                )
            }
        )
    }

    private static func decimate(_ ring: [CLLocationCoordinate2D], maxPoints: Int) -> [CLLocationCoordinate2D] {
        guard ring.count > maxPoints, maxPoints >= 3 else { return ring }

        let step = Double(ring.count) / Double(maxPoints)
        var result: [CLLocationCoordinate2D] = []
        result.reserveCapacity(maxPoints)

        var index = 0.0
        while Int(index) < ring.count, result.count < maxPoints {
            result.append(ring[Int(index)])
            index += step
        }

        if let first = ring.first,
           let last = result.last,
           !coordinatesEqual(last, first) {
            result.append(first)
        }

        return result
    }

    private func pointInPolygon(_ point: CLLocationCoordinate2D, polygon: [CLLocationCoordinate2D]) -> Bool {
        guard polygon.count >= 3 else { return false }

        var inside = false
        var previous = polygon.last!

        for current in polygon {
            let intersects = ((current.latitude > point.latitude) != (previous.latitude > point.latitude))
                && (point.longitude < (previous.longitude - current.longitude)
                    * (point.latitude - current.latitude)
                    / (previous.latitude - current.latitude)
                    + current.longitude)

            if intersects {
                inside.toggle()
            }
            previous = current
        }

        return inside
    }

    static func == (lhs: MunicipalityBoundary, rhs: MunicipalityBoundary) -> Bool {
        lhs.polygons.count == rhs.polygons.count
    }

    private static func coordinatesEqual(_ lhs: CLLocationCoordinate2D, _ rhs: CLLocationCoordinate2D) -> Bool {
        lhs.latitude == rhs.latitude && lhs.longitude == rhs.longitude
    }
}
