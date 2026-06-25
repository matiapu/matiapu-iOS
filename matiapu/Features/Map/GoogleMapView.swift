//
//  GoogleMapView.swift
//  matiapu
//

import CoreLocation
import GoogleMaps
import SwiftUI

struct GoogleMapView: View {
    let posts: [Post]
    let mapCenter: CLLocationCoordinate2D
    let selectedPostID: String?
    let onMarkerTap: (Post) -> Void
    let onMapTap: () -> Void

    var body: some View {
        if GoogleMapsConfigurator.isConfigured {
            GoogleMapViewRepresentable(
                posts: posts,
                mapCenter: mapCenter,
                selectedPostID: selectedPostID,
                onMarkerTap: onMarkerTap,
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
    let mapCenter: CLLocationCoordinate2D
    let selectedPostID: String?
    let onMarkerTap: (Post) -> Void
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
        mapView.isMyLocationEnabled = true
        mapView.settings.myLocationButton = true
        mapView.settings.compassButton = true
        mapView.delegate = context.coordinator
        context.coordinator.lastMapCenter = mapCenter
        context.coordinator.updateMarkers(on: mapView, posts: posts, selectedPostID: selectedPostID)
        return mapView
    }

    func updateUIView(_ mapView: GMSMapView, context: Context) {
        context.coordinator.parent = self
        context.coordinator.updateCameraIfNeeded(on: mapView, center: mapCenter)
        context.coordinator.updateMarkers(on: mapView, posts: posts, selectedPostID: selectedPostID)
    }

    final class Coordinator: NSObject, GMSMapViewDelegate {
        var parent: GoogleMapViewRepresentable
        private var markers: [GMSMarker] = []
        private var displayedPostIDs: [String] = []
        private var displayedSelectedPostID: String?
        fileprivate var lastMapCenter: CLLocationCoordinate2D?

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

        func updateMarkers(on mapView: GMSMapView, posts: [Post], selectedPostID: String?) {
            let mappablePosts = posts.filter { $0.location != nil }
            let postIDs = mappablePosts.map(\.id)
            let postsChanged = postIDs != displayedPostIDs

            if postsChanged {
                markers.forEach { $0.map = nil }
                markers = mappablePosts.compactMap { post in
                    guard let location = post.location else { return nil }

                    let contentView = MapPinMarkerContentView(tag: post.tag)
                    let marker = GMSMarker(position: location.coordinate)
                    marker.iconView = contentView
                    marker.groundAnchor = CGPoint(x: 0.5, y: 1.0)
                    marker.userData = post.id
                    marker.map = mapView
                    return marker
                }
                displayedPostIDs = postIDs
            }

            if postsChanged || selectedPostID != displayedSelectedPostID {
                applyMarkerAppearance(
                    selectedPostID: selectedPostID,
                    animated: !postsChanged
                )
                displayedSelectedPostID = selectedPostID
            }
        }

        private func applyMarkerAppearance(selectedPostID: String?, animated: Bool) {
            for marker in markers {
                guard let postID = marker.userData as? String else { continue }

                let isSelected = postID == selectedPostID
                marker.zIndex = isSelected ? Int32.max : 0

                if let contentView = marker.iconView as? MapPinMarkerContentView {
                    contentView.setSelected(isSelected, animated: animated, marker: marker)
                }
            }
        }

        func mapView(_ mapView: GMSMapView, didTap marker: GMSMarker) -> Bool {
            guard let postID = marker.userData as? String,
                  let post = parent.posts.first(where: { $0.id == postID }) else {
                return false
            }

            parent.onMarkerTap(post)
            return true
        }

        func mapView(_ mapView: GMSMapView, didTapAt coordinate: CLLocationCoordinate2D) {
            parent.onMapTap()
        }
    }
}

/// 地図ピンの表示用ビュー。選択時の拡大をアニメーションする。
private final class MapPinMarkerContentView: UIView {
    private let imageView = UIImageView()
    private let postTag: String

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

    func setSelected(_ isSelected: Bool, animated: Bool, marker: GMSMarker) {
        imageView.image = MapPinMarkerFactory.makeIcon(forTag: postTag, isSelected: isSelected)

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
