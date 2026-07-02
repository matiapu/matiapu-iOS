//
//  MunicipalityBoundaryGeoJSONParser.swift
//  matiapu
//

import CoreLocation
import Foundation

nonisolated enum MunicipalityBoundaryGeoJSONParser {
    enum ParseError: Error {
        case invalidFormat
        case missingGeometry
    }

    static func parse(data: Data) throws -> MunicipalityBoundary {
        let json = try JSONSerialization.jsonObject(with: data)
        let features: [[String: Any]]

        switch json {
        case let collection as [String: Any]:
            guard let rawFeatures = collection["features"] as? [[String: Any]] else {
                throw ParseError.invalidFormat
            }
            features = rawFeatures
        case let feature as [String: Any]:
            features = [feature]
        default:
            throw ParseError.invalidFormat
        }

        var polygons: [MunicipalityBoundary.Polygon] = []

        for feature in features {
            guard let geometry = feature["geometry"] as? [String: Any],
                  let type = geometry["type"] as? String,
                  let coordinates = geometry["coordinates"] else {
                continue
            }

            switch type {
            case "Polygon":
                if let polygon = parsePolygon(coordinates) {
                    polygons.append(polygon)
                }
            case "MultiPolygon":
                if let multi = coordinates as? [[[ [Double]]]] {
                    polygons.append(contentsOf: multi.compactMap(parsePolygonRings))
                }
            default:
                continue
            }
        }

        guard !polygons.isEmpty else { throw ParseError.missingGeometry }
        return MunicipalityBoundary(polygons: polygons)
    }

    private static func parsePolygon(_ coordinates: Any) -> MunicipalityBoundary.Polygon? {
        guard let rings = coordinates as? [[[Double]]] else { return nil }
        return parsePolygonRings(rings)
    }

    private static func parsePolygonRings(_ rings: [[[Double]]]) -> MunicipalityBoundary.Polygon? {
        guard let exteriorRaw = rings.first else { return nil }

        let exterior = ring(from: exteriorRaw)
        guard exterior.count >= 3 else { return nil }

        let holes = rings.dropFirst().map(ring(from:)).filter { $0.count >= 3 }
        return MunicipalityBoundary.Polygon(exterior: exterior, holes: holes)
    }

    private static func ring(from positions: [[Double]]) -> [CLLocationCoordinate2D] {
        positions.compactMap { position in
            guard position.count >= 2 else { return nil }
            return CLLocationCoordinate2D(latitude: position[1], longitude: position[0])
        }
    }
}
