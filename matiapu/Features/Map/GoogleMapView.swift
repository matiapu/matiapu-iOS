//
//  GoogleMapView.swift
//  matiapu
//

import CoreLocation
import GoogleMaps
import SwiftUI
import UIKit

struct GoogleMapView: View {
    let posts: [Post]
    let shelters: [Shelter]
    let disasters: [Disaster]
    let mapCenter: CLLocationCoordinate2D
    let municipalityScope: MapMunicipalityScope?
    let selectedPostID: String?
    let selectedShelterID: String?
    var isLocationTrackingEnabled = true
    let onPostTap: (Post) -> Void
    let onShelterTap: (Shelter) -> Void
    let onMapTap: () -> Void

    var body: some View {
        if GoogleMapsConfigurator.isConfigured {
            GoogleMapViewRepresentable(
                posts: posts,
                shelters: shelters,
                disasters: disasters,
                mapCenter: mapCenter,
                municipalityScope: municipalityScope,
                selectedPostID: selectedPostID,
                selectedShelterID: selectedShelterID,
                isLocationTrackingEnabled: isLocationTrackingEnabled,
                onPostTap: onPostTap,
                onShelterTap: onShelterTap,
                onMapTap: onMapTap
            )
        } else {
            ContentUnavailableView(
                "地図を読み込めません",
                systemImage: "map",
            )
        }
    }
}

private struct GoogleMapViewRepresentable: UIViewRepresentable {
    let posts: [Post]
    let shelters: [Shelter]
    let disasters: [Disaster]
    let mapCenter: CLLocationCoordinate2D
    let municipalityScope: MapMunicipalityScope?
    let selectedPostID: String?
    let selectedShelterID: String?
    let isLocationTrackingEnabled: Bool
    let onPostTap: (Post) -> Void
    let onShelterTap: (Shelter) -> Void
    let onMapTap: () -> Void

    func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }

    func makeUIView(context: Context) -> GMSMapView {
        let options = GMSMapViewOptions()
        options.camera = GMSCameraPosition.camera(
            withTarget: mapCenter,
            zoom: MapConstants.defaultZoom
        )
        let mapView = GMSMapView(options: options)
        mapView.isMyLocationEnabled = isLocationTrackingEnabled
        mapView.settings.myLocationButton = true
        mapView.settings.compassButton = true
        mapView.delegate = context.coordinator
        context.coordinator.lastMapCenter = mapCenter
        context.coordinator.syncOverlays(on: mapView)
        return mapView
    }

    func updateUIView(_ mapView: GMSMapView, context: Context) {
        context.coordinator.parent = self
        if mapView.isMyLocationEnabled != isLocationTrackingEnabled {
            mapView.isMyLocationEnabled = isLocationTrackingEnabled
        }
        context.coordinator.updateCameraIfNeeded(on: mapView, center: mapCenter)
        context.coordinator.syncOverlays(on: mapView)
    }

    final class Coordinator: NSObject, GMSMapViewDelegate {
        var parent: GoogleMapViewRepresentable
        private var postMarkers: [GMSMarker] = []
        private var shelterMarkers: [GMSMarker] = []
        private var disasterPolygons: [GMSPolygon] = []
        private var dimmingPolygon: GMSPolygon?
        private var boundaryOutlinePolygons: [GMSPolygon] = []
        private var displayedPostIDs: [String] = []
        private var displayedShelterIDs: [String] = []
        private var displayedDisasterIDs: [String] = []
        private var displayedSelectedPostID: String?
        private var displayedSelectedShelterID: String?
        fileprivate var lastMapCenter: CLLocationCoordinate2D?
        fileprivate var lastMunicipalityScope: MapMunicipalityScope?

        init(parent: GoogleMapViewRepresentable) {
            self.parent = parent
        }

        func updateCameraIfNeeded(on mapView: GMSMapView, center: CLLocationCoordinate2D) {
            if let lastMapCenter,
               abs(lastMapCenter.latitude - center.latitude) < 0.000001,
               abs(lastMapCenter.longitude - center.longitude) < 0.000001 {
                return
            }

            lastMapCenter = center
            let camera = GMSCameraPosition.camera(
                withTarget: center,
                zoom: MapConstants.defaultZoom
            )
            mapView.animate(to: camera)
        }

        func syncOverlays(on mapView: GMSMapView) {
            syncDimmingOverlay(on: mapView)
            syncPostMarkers(on: mapView)
            syncShelterMarkers(on: mapView)
            syncDisasterPolygons(on: mapView)
        }

        private func syncDimmingOverlay(on mapView: GMSMapView) {
            let scope = parent.municipalityScope
            guard scope != lastMunicipalityScope else { return }

            dimmingPolygon?.map = nil
            dimmingPolygon = nil
            boundaryOutlinePolygons.forEach { $0.map = nil }
            boundaryOutlinePolygons = []

            if let scope {
                dimmingPolygon = MunicipalityDimmingOverlay.makeDimmingPolygon(for: scope.boundary)
                dimmingPolygon?.map = mapView

                boundaryOutlinePolygons = MunicipalityDimmingOverlay.makeBoundaryOutline(for: scope.boundary)
                boundaryOutlinePolygons.forEach { $0.map = mapView }
            }

            lastMunicipalityScope = scope
        }

        private func syncPostMarkers(on mapView: GMSMapView) {
            let mappablePosts = parent.posts.filter { $0.location != nil }
            let postIDs = mappablePosts.map(\.id)
            let postsChanged = postIDs != displayedPostIDs

            if postsChanged {
                postMarkers.forEach { $0.map = nil }
                postMarkers = mappablePosts.compactMap { post in
                    guard let location = post.location else { return nil }

                    let contentView = MapPinMarkerContentView(tag: post.tag)
                    let marker = GMSMarker(position: location.coordinate)
                    marker.iconView = contentView
                    marker.groundAnchor = CGPoint(x: 0.5, y: 1.0)
                    marker.userData = MapMarkerPayload.post(post.id)
                    marker.map = mapView
                    return marker
                }
                displayedPostIDs = postIDs
            }

            if postsChanged || parent.selectedPostID != displayedSelectedPostID {
                applyPostMarkerAppearance(
                    selectedPostID: parent.selectedPostID,
                    animated: !postsChanged
                )
                displayedSelectedPostID = parent.selectedPostID
            }
        }

        private func syncShelterMarkers(on mapView: GMSMapView) {
            let shelterIDs = parent.shelters.map(\.id)
            let sheltersChanged = shelterIDs != displayedShelterIDs

            if sheltersChanged {
                shelterMarkers.forEach { $0.map = nil }
                shelterMarkers = parent.shelters.map { shelter in
                    let marker = GMSMarker(
                        position: CLLocationCoordinate2D(
                            latitude: shelter.latitude,
                            longitude: shelter.longitude
                        )
                    )
                    marker.icon = ShelterMarkerFactory.makeIcon(isSelected: false)
                    marker.groundAnchor = CGPoint(x: 0.5, y: 1.0)
                    marker.userData = MapMarkerPayload.shelter(shelter.id)
                    marker.zIndex = 1
                    marker.map = mapView
                    return marker
                }
                displayedShelterIDs = shelterIDs
            }

            if sheltersChanged || parent.selectedShelterID != displayedSelectedShelterID {
                for marker in shelterMarkers {
                    guard case .shelter(let shelterID) = marker.userData as? MapMarkerPayload else { continue }
                    let isSelected = shelterID == parent.selectedShelterID
                    marker.icon = ShelterMarkerFactory.makeIcon(isSelected: isSelected)
                    marker.zIndex = isSelected ? Int32.max - 1 : 1
                }
                displayedSelectedShelterID = parent.selectedShelterID
            }
        }

        private func syncDisasterPolygons(on mapView: GMSMapView) {
            let disasterIDs = parent.disasters.map(\.id)
            guard disasterIDs != displayedDisasterIDs else { return }

            disasterPolygons.forEach { $0.map = nil }
            disasterPolygons = parent.disasters.compactMap { disaster in
                guard disaster.dangerZone.count >= 3 else { return nil }

                let path = GMSMutablePath()
                disaster.dangerZone.forEach {
                    path.add(CLLocationCoordinate2D(latitude: $0.latitude, longitude: $0.longitude))
                }

                let polygon = GMSPolygon(path: path)
                let style = DisasterMapStyle.style(for: disaster.disasterType)
                polygon.fillColor = style.fillColor
                polygon.strokeColor = style.strokeColor
                polygon.strokeWidth = 2
                polygon.userData = disaster.id
                polygon.map = mapView
                return polygon
            }
            displayedDisasterIDs = disasterIDs
        }

        private func applyPostMarkerAppearance(selectedPostID: String?, animated: Bool) {
            for marker in postMarkers {
                guard case .post(let postID) = marker.userData as? MapMarkerPayload else { continue }

                let isSelected = postID == selectedPostID
                marker.zIndex = isSelected ? Int32.max : 0

                if let contentView = marker.iconView as? MapPinMarkerContentView,
                   let post = parent.posts.first(where: { $0.id == postID }) {
                    contentView.setSelected(isSelected, animated: animated, marker: marker, tag: post.tag)
                }
            }
        }

        func mapView(_ mapView: GMSMapView, didTap marker: GMSMarker) -> Bool {
            switch marker.userData as? MapMarkerPayload {
            case .post(let postID):
                guard let post = parent.posts.first(where: { $0.id == postID }) else { return false }
                parent.onPostTap(post)
                return true
            case .shelter(let shelterID):
                guard let shelter = parent.shelters.first(where: { $0.id == shelterID }) else { return false }
                parent.onShelterTap(shelter)
                return true
            case .none:
                return false
            }
        }

        func mapView(_ mapView: GMSMapView, didTapAt coordinate: CLLocationCoordinate2D) {
            parent.onMapTap()
        }
    }
}

private enum DisasterMapStyle {
    struct Colors {
        let fillColor: UIColor
        let strokeColor: UIColor
    }

    static func style(for type: DisasterType) -> Colors {
        switch type {
        case .flood:
            Colors(
                fillColor: UIColor.systemBlue.withAlphaComponent(0.25),
                strokeColor: UIColor.systemBlue.withAlphaComponent(0.8)
            )
        case .landslide:
            Colors(
                fillColor: UIColor.brown.withAlphaComponent(0.25),
                strokeColor: UIColor.brown.withAlphaComponent(0.8)
            )
        case .tsunami:
            Colors(
                fillColor: UIColor.systemTeal.withAlphaComponent(0.25),
                strokeColor: UIColor.systemTeal.withAlphaComponent(0.8)
            )
        case .earthquake:
            Colors(
                fillColor: UIColor.systemOrange.withAlphaComponent(0.25),
                strokeColor: UIColor.systemOrange.withAlphaComponent(0.8)
            )
        }
    }
}

private enum ShelterMarkerFactory {
    static func makeIcon(isSelected: Bool) -> UIImage? {
        let size = CGSize(width: isSelected ? 36 : 30, height: isSelected ? 36 : 30)
        let config = UIImage.SymbolConfiguration(pointSize: isSelected ? 18 : 15, weight: .semibold)
        let image = UIImage(systemName: "house.fill", withConfiguration: config)?
            .withTintColor(isSelected ? .systemOrange : .systemBlue, renderingMode: .alwaysOriginal)

        guard let image else { return nil }

        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image { _ in
            image.draw(in: CGRect(origin: .zero, size: size))
        }
    }
}

/// 地図ピンの表示用ビュー。選択時の拡大をアニメーションする。
private final class MapPinMarkerContentView: UIView {
    private let imageView = UIImageView()
    private var postTag: String

    init(tag: String) {
        self.postTag = tag
        super.init(frame: CGRect(origin: .zero, size: MapPinMarkerFactory.markerSize))
        imageView.frame = bounds
        imageView.contentMode = .scaleToFill
        imageView.image = MapPinMarkerFactory.makeIcon(forTag: tag, isSelected: false)
        addSubview(imageView)
        configureBottomAnchor()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func setSelected(_ isSelected: Bool, animated: Bool, marker: GMSMarker, tag: String) {
        postTag = tag
        imageView.image = MapPinMarkerFactory.makeIcon(forTag: tag, isSelected: isSelected)

        let scale = isSelected ? MapPinMarkerFactory.selectedScale : 1.0
        let targetTransform = CGAffineTransform(scaleX: scale, y: scale)

        guard animated else {
            transform = targetTransform
            return
        }

        marker.tracksViewChanges = true
        UIView.animate(
            withDuration: MapPinMarkerFactory.selectionAnimationDuration,
            delay: 0,
            usingSpringWithDamping: 0.72,
            initialSpringVelocity: 0.8,
            options: [.curveEaseInOut, .allowUserInteraction]
        ) {
            self.transform = targetTransform
        } completion: { _ in
            marker.tracksViewChanges = false
        }
    }

    private func configureBottomAnchor() {
        let size = bounds.size
        layer.anchorPoint = CGPoint(x: 0.5, y: 1.0)
        layer.position = CGPoint(x: size.width / 2, y: size.height)
    }
}
