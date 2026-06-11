//
//  GoogleMapView.swift
//  matiapu
//

import GoogleMaps
import SwiftUI

struct GoogleMapView: View {
    let posts: [Post]

    var body: some View {
        if GoogleMapsConfigurator.isConfigured {
            GoogleMapViewRepresentable(posts: posts)
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

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    func makeUIView(context: Context) -> GMSMapView {
        let options = GMSMapViewOptions()
        options.camera = GMSCameraPosition.camera(
            withTarget: MapConstants.defaultCenter,
            zoom: MapConstants.defaultZoom
        )
        let mapView = GMSMapView(options: options)
        mapView.settings.compassButton = true
        context.coordinator.updateMarkers(on: mapView, posts: posts)
        return mapView
    }

    func updateUIView(_ mapView: GMSMapView, context: Context) {
        context.coordinator.updateMarkers(on: mapView, posts: posts)
    }

    final class Coordinator {
        private var markers: [GMSMarker] = []
        private var displayedPostIDs: [String] = []

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
                marker.title = post.title.isEmpty ? post.tag : post.title
                marker.snippet = post.body
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
    }
}
