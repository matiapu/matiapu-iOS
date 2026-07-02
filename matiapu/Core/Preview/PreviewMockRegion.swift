//
//  PreviewMockRegion.swift
//  matiapu
//

import CoreLocation

/// プレビュー・モックデータ専用のサンプル地域（本番の地図中心決定には使わない）
enum PreviewMockRegion {
    static let municipalityName = "新宿区"
    static let center = CLLocationCoordinate2D(latitude: 35.6939, longitude: 139.7036)
}
