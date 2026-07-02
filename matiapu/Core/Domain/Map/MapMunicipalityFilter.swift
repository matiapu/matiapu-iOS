//
//  MapMunicipalityFilter.swift
//  matiapu
//

import CoreLocation
import Foundation

nonisolated enum MapMunicipalityFilter {
    static func shelters(
        _ shelters: [Shelter],
        municipality: String?,
        boundary: MunicipalityBoundary?
    ) -> [Shelter] {
        guard let municipality, !municipality.isEmpty else { return shelters }

        let namedMatches = shelters.filter { $0.municipality == municipality }
        if !namedMatches.isEmpty {
            return namedMatches
        }

        guard let boundary else { return [] }
        return shelters.filter { shelter in
            boundary.contains(
                CLLocationCoordinate2D(latitude: shelter.latitude, longitude: shelter.longitude)
            )
        }
    }

    static func disasters(
        _ disasters: [Disaster],
        within boundary: MunicipalityBoundary?
    ) -> [Disaster] {
        guard let boundary else { return disasters }

        return disasters.filter { disaster in
            disaster.dangerZone.contains { point in
                boundary.contains(
                    CLLocationCoordinate2D(latitude: point.latitude, longitude: point.longitude)
                )
            }
        }
    }

    static func posts(
        _ posts: [Post],
        municipality: String?,
        boundary: MunicipalityBoundary?
    ) -> [Post] {
        let located = posts.filter { $0.location != nil }

        if let boundary {
            return located.filter { post in
                guard let location = post.location else { return false }
                if boundary.contains(
                    CLLocationCoordinate2D(latitude: location.latitude, longitude: location.longitude)
                ) {
                    return true
                }
                if let municipality, let postMunicipality = post.municipality {
                    return postMunicipality == municipality
                }
                return false
            }
        }

        guard let municipality, !municipality.isEmpty else { return located }

        return located.filter { post in
            guard let postMunicipality = post.municipality else { return true }
            return postMunicipality == municipality
        }
    }
}
