//
//  MunicipalityBounds.swift
//  matiapu
//

import CoreLocation
import Foundation

nonisolated struct MunicipalityBounds: Equatable, Sendable {
    let southWest: CLLocationCoordinate2D
    let northEast: CLLocationCoordinate2D

    func contains(_ coordinate: CLLocationCoordinate2D) -> Bool {
        coordinate.latitude >= southWest.latitude
            && coordinate.latitude <= northEast.latitude
            && coordinate.longitude >= southWest.longitude
            && coordinate.longitude <= northEast.longitude
    }

    var center: CLLocationCoordinate2D {
        CLLocationCoordinate2D(
            latitude: (southWest.latitude + northEast.latitude) / 2,
            longitude: (southWest.longitude + northEast.longitude) / 2
        )
    }

    static func square(around center: CLLocationCoordinate2D, radiusDegrees: Double) -> MunicipalityBounds {
        MunicipalityBounds(
            southWest: CLLocationCoordinate2D(
                latitude: center.latitude - radiusDegrees,
                longitude: center.longitude - radiusDegrees
            ),
            northEast: CLLocationCoordinate2D(
                latitude: center.latitude + radiusDegrees,
                longitude: center.longitude + radiusDegrees
            )
        )
    }

    static func == (lhs: MunicipalityBounds, rhs: MunicipalityBounds) -> Bool {
        lhs.southWest.latitude == rhs.southWest.latitude
            && lhs.southWest.longitude == rhs.southWest.longitude
            && lhs.northEast.latitude == rhs.northEast.latitude
            && lhs.northEast.longitude == rhs.northEast.longitude
    }
}
