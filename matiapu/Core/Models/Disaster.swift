//
//  Disaster.swift
//  matiapu
//

import Foundation

enum DisasterType: String, CaseIterable, Hashable, Sendable {
    case flood = "洪水"
    case landslide = "土砂"
    case tsunami = "津波"
    case earthquake = "地震"
}

struct DangerZonePoint: Hashable, Sendable {
    let latitude: Double
    let longitude: Double
}

struct Disaster: Identifiable, Hashable {
    let id: String
    let disasterType: DisasterType
    let dangerZone: [DangerZonePoint]
    let occurredAt: Date
    let createdAt: Date
}

struct CreateDisasterInput: Sendable {
    let disasterType: DisasterType
    let dangerZone: [DangerZonePoint]
    let occurredAt: Date
}
