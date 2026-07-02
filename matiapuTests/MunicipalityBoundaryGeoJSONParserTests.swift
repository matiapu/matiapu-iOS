//
//  MunicipalityBoundaryGeoJSONParserTests.swift
//  matiapuTests
//

import CoreLocation
import XCTest
@testable import matiapu

final class MunicipalityBoundaryGeoJSONParserTests: XCTestCase {
    private let minimalPolygonJSON = """
    {
      "type": "FeatureCollection",
      "features": [{
        "type": "Feature",
        "geometry": {
          "type": "Polygon",
          "coordinates": [[[139.5, 35.6], [139.6, 35.6], [139.6, 35.7], [139.5, 35.7], [139.5, 35.6]]]
        }
      }]
    }
    """

    func testParse_minimalPolygon() throws {
        let data = Data(minimalPolygonJSON.utf8)
        let boundary = try MunicipalityBoundaryGeoJSONParser.parse(data: data)

        XCTAssertFalse(boundary.polygons.isEmpty)
        XCTAssertTrue(boundary.contains(CLLocationCoordinate2D(latitude: 35.65, longitude: 139.55)))
        XCTAssertFalse(boundary.contains(CLLocationCoordinate2D(latitude: 35.0, longitude: 139.0)))
    }

    func testParse_invalidFormatThrows() {
        let data = Data("{}".utf8)

        XCTAssertThrowsError(try MunicipalityBoundaryGeoJSONParser.parse(data: data)) { error in
            guard case MunicipalityBoundaryGeoJSONParser.ParseError.invalidFormat = error else {
                return XCTFail("unexpected error: \(error)")
            }
        }
    }
}
