//
//  MunicipalityDimmingOverlay.swift
//  matiapu
//

import CoreLocation
import GoogleMaps
import UIKit

enum MunicipalityDimmingOverlay {
    static func makeDimmingPolygon(for boundary: MunicipalityBoundary) -> GMSPolygon {
        let outer = GMSMutablePath()
        outer.add(CLLocationCoordinate2D(latitude: 20.0, longitude: 122.0))
        outer.add(CLLocationCoordinate2D(latitude: 20.0, longitude: 154.0))
        outer.add(CLLocationCoordinate2D(latitude: 46.0, longitude: 154.0))
        outer.add(CLLocationCoordinate2D(latitude: 46.0, longitude: 122.0))

        let holes = boundary.polygons.map { polygon -> GMSPath in
            path(from: polygon.exterior)
        }

        let polygon = GMSPolygon(path: outer)
        polygon.holes = holes
        polygon.fillColor = UIColor.black.withAlphaComponent(0.38)
        polygon.strokeWidth = 0
        polygon.zIndex = -1
        polygon.isTappable = false
        return polygon
    }

    static func makeBoundaryOutline(for boundary: MunicipalityBoundary) -> [GMSPolygon] {
        boundary.polygons.map { polygon in
            let outline = GMSPolygon(path: path(from: polygon.exterior))
            outline.fillColor = UIColor.clear
            outline.strokeColor = UIColor.systemBlue.withAlphaComponent(0.85)
            outline.strokeWidth = 2
            outline.zIndex = 0
            outline.isTappable = false
            return outline
        }
    }

    private static func path(from ring: [CLLocationCoordinate2D]) -> GMSMutablePath {
        let path = GMSMutablePath()
        ring.forEach { path.add($0) }
        return path
    }
}
