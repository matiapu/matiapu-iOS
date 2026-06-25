//
//  LocationCaptureService.swift
//  matiapu
//

import CoreLocation
import Foundation

@MainActor
final class LocationCaptureService: NSObject {
    private let manager = CLLocationManager()
    private(set) var latestLocation: CLLocation?
    private(set) var authorizationStatus: CLAuthorizationStatus
    var onLocationUpdate: ((CLLocation) -> Void)?

    override init() {
        authorizationStatus = manager.authorizationStatus
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyBest
    }

    func prepareForCapture() {
        authorizationStatus = manager.authorizationStatus

        switch authorizationStatus {
        case .notDetermined:
            manager.requestWhenInUseAuthorization()
        case .authorizedWhenInUse, .authorizedAlways:
            manager.startUpdatingLocation()
        default:
            break
        }
    }

    func stopCapture() {
        manager.stopUpdatingLocation()
    }

    var currentCoordinate: CLLocationCoordinate2D? {
        latestLocation?.coordinate
    }

    func waitForLocation(timeout: TimeInterval = 3) async -> CLLocationCoordinate2D? {
        if let currentCoordinate {
            return currentCoordinate
        }

        let clock = ContinuousClock()
        let deadline = clock.now + .seconds(timeout)

        while clock.now < deadline {
            if let currentCoordinate {
                return currentCoordinate
            }
            try? await Task.sleep(for: .milliseconds(200))
        }

        return currentCoordinate
    }
}

extension LocationCaptureService: CLLocationManagerDelegate {
    nonisolated func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        Task { @MainActor in
            authorizationStatus = manager.authorizationStatus

            switch authorizationStatus {
            case .authorizedWhenInUse, .authorizedAlways:
                manager.startUpdatingLocation()
            default:
                manager.stopUpdatingLocation()
            }
        }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }

        Task { @MainActor in
            latestLocation = location
            onLocationUpdate?(location)
        }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        // 位置情報取得失敗時は写真EXIFのみにフォールバックする
    }
}

enum PostLocationResolver {
    static func resolve(
        photoCoordinate: CLLocationCoordinate2D?,
        deviceCoordinate: CLLocationCoordinate2D?
    ) -> PostLocation? {
        if let photoCoordinate {
            return PostLocation(coordinate: photoCoordinate)
        }

        if let deviceCoordinate {
            return PostLocation(coordinate: deviceCoordinate)
        }

        return nil
    }
}
