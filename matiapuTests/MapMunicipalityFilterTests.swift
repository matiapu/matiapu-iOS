//
//  MapMunicipalityFilterTests.swift
//  matiapuTests
//

import CoreLocation
import XCTest
@testable import matiapu

final class MapMunicipalityFilterTests: XCTestCase {
    private let municipality = "調布市"

    private var squareBoundary: MunicipalityBoundary {
        let ring: [CLLocationCoordinate2D] = [
            CLLocationCoordinate2D(latitude: 35.6, longitude: 139.5),
            CLLocationCoordinate2D(latitude: 35.6, longitude: 139.6),
            CLLocationCoordinate2D(latitude: 35.7, longitude: 139.6),
            CLLocationCoordinate2D(latitude: 35.7, longitude: 139.5),
            CLLocationCoordinate2D(latitude: 35.6, longitude: 139.5),
        ]
        return MunicipalityBoundary(
            polygons: [MunicipalityBoundary.Polygon(exterior: ring, holes: [])]
        )
    }

    func testShelters_prefersMunicipalityNameMatch() {
        let shelters = [
            Shelter(id: "1", shelterName: "A", latitude: 35.0, longitude: 139.0, capacity: nil, municipality: municipality),
            Shelter(id: "2", shelterName: "B", latitude: 35.0, longitude: 140.0, capacity: nil, municipality: "八王子市"),
        ]

        let result = MapMunicipalityFilter.shelters(shelters, municipality: municipality, boundary: squareBoundary)

        XCTAssertEqual(result.map(\.id), ["1"])
    }

    func testShelters_filtersByBoundaryWhenNameMissing() {
        let shelters = [
            Shelter(id: "inside", shelterName: "A", latitude: 35.65, longitude: 139.55, capacity: nil, municipality: nil),
            Shelter(id: "outside", shelterName: "B", latitude: 35.0, longitude: 139.0, capacity: nil, municipality: nil),
        ]

        let result = MapMunicipalityFilter.shelters(shelters, municipality: municipality, boundary: squareBoundary)

        XCTAssertEqual(result.map(\.id), ["inside"])
    }

    func testPosts_filtersByBoundaryAndMunicipalityFallback() {
        let inside = Post(
            id: "inside",
            authorName: "A",
            tag: "tag",
            title: "title",
            body: "body",
            postedAt: Date(),
            location: PostLocation(latitude: 35.65, longitude: 139.55),
            municipality: municipality
        )
        let outside = Post(
            id: "outside",
            authorName: "B",
            tag: "tag",
            title: "title",
            body: "body",
            postedAt: Date(),
            location: PostLocation(latitude: 35.0, longitude: 139.0),
            municipality: "八王子市"
        )
        let noLocation = Post(
            id: "no-location",
            authorName: "C",
            tag: "tag",
            title: "title",
            body: "body",
            postedAt: Date(),
            location: nil,
            municipality: municipality
        )

        let result = MapMunicipalityFilter.posts(
            [inside, outside, noLocation],
            municipality: municipality,
            boundary: squareBoundary
        )

        XCTAssertEqual(Set(result.map(\.id)), ["inside"])
    }

    func testDisasters_filtersDangerZonePointsWithinBoundary() {
        let inside = Disaster(
            id: "inside",
            disasterType: .flood,
            dangerZone: [DangerZonePoint(latitude: 35.65, longitude: 139.55)],
            occurredAt: Date(),
            createdAt: Date()
        )
        let outside = Disaster(
            id: "outside",
            disasterType: .flood,
            dangerZone: [DangerZonePoint(latitude: 35.0, longitude: 139.0)],
            occurredAt: Date(),
            createdAt: Date()
        )

        let result = MapMunicipalityFilter.disasters([inside, outside], within: squareBoundary)

        XCTAssertEqual(result.map(\.id), ["inside"])
    }
}
