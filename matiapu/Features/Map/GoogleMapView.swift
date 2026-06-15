//
//  GoogleMapView.swift
//  matiapu
//

import GoogleMaps
import SwiftUI

struct GoogleMapView: View {
    let posts: [Post]
    let onMarkerTap: (Post) -> Void
    let onMapTap: () -> Void

    var body: some View {
        if GoogleMapsConfigurator.isConfigured {
            GoogleMapViewRepresentable(
                posts: posts,
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
    let onMarkerTap: (Post) -> Void
    let onMapTap: () -> Void

    func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }

    func makeUIView(context: Context) -> GMSMapView {
        let options = GMSMapViewOptions()
        options.camera = GMSCameraPosition.camera(
            withTarget: MapConstants.defaultCenter,
            zoom: MapConstants.defaultZoom
        )
        let mapView = GMSMapView(options: options)
        mapView.settings.compassButton = true
        mapView.delegate = context.coordinator
        context.coordinator.updateMarkers(on: mapView, posts: posts)
        return mapView
    }

    func updateUIView(_ mapView: GMSMapView, context: Context) {
        context.coordinator.parent = self
        context.coordinator.updateMarkers(on: mapView, posts: posts)
    }

    final class Coordinator: NSObject, GMSMapViewDelegate {
        var parent: GoogleMapViewRepresentable
        private var markers: [GMSMarker] = []
        private var displayedPostIDs: [String] = []

        init(parent: GoogleMapViewRepresentable) {
            self.parent = parent
        }

        func updateMarkers(on mapView: GMSMapView, posts: [Post]) {
            let mappablePosts = posts.filter { $0.location != nil }
            let postIDs = mappablePosts.map(\.id)

            guard postIDs != displayedPostIDs else { return }

            markers.forEach { $0.map = nil }
            markers = mappablePosts.compactMap { post in
                guard let location = post.location else { return nil }

                let marker = GMSMarker(position: location.coordinate)
                marker.icon = MapPinMarkerFactory.makeIcon(forTag: post.tag)
                marker.groundAnchor = CGPoint(x: 0.5, y: 1.0)
                marker.userData = post.id
                marker.map = mapView
                return marker
            }
            displayedPostIDs = postIDs

            if let firstLocation = mappablePosts.first?.location, mappablePosts.count == 1 {
                let camera = GMSCameraPosition.camera(
                    withTarget: firstLocation.coordinate,
                    zoom: MapConstants.focusedZoom
                )
                mapView.animate(to: camera)
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
