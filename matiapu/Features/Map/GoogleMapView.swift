//
//  GoogleMapView.swift
//  matiapu
//

import GoogleMaps
import SwiftUI

struct GoogleMapView: View {
  var body: some View {
    if GoogleMapsConfigurator.configureIfNeeded() {
      GoogleMapViewRepresentable()
    } else {
      ContentUnavailableView(
        "地図を読み込めません",
        systemImage: "map",
      )
    }
  }
}

private struct GoogleMapViewRepresentable: UIViewRepresentable {
  func makeUIView(context: Context) -> GMSMapView {
      let options = GMSMapViewOptions()
      options.camera = GMSCameraPosition.camera(
        withTarget: MapConstants.chofuCenter,
        zoom: MapConstants.defaultZoom
      )
      let mapView = GMSMapView(options: options)
      mapView.settings.compassButton = true
      return mapView
    }
  
  func updateUIView(_ mapView: GMSMapView, context: Context) {}
}
