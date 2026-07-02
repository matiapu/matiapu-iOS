//
//  MockDisasterRepository.swift
//  matiapu
//

import CoreLocation
import Foundation

final class MockDisasterRepository: DisasterRepository, @unchecked Sendable {
    private let disasters: [Disaster] = [
        Disaster(
            id: "mock-disaster-1",
            disasterType: .flood,
            dangerZone: [
                DangerZonePoint(latitude: 35.6950, longitude: 139.7020),
                DangerZonePoint(latitude: 35.6950, longitude: 139.7080),
                DangerZonePoint(latitude: 35.6900, longitude: 139.7080),
                DangerZonePoint(latitude: 35.6900, longitude: 139.7020),
            ],
            occurredAt: .now.addingTimeInterval(-86_400),
            createdAt: .now.addingTimeInterval(-86_400)
        ),
    ]

    func createDisaster(_ input: CreateDisasterInput) async throws -> Disaster {
        Disaster(
            id: UUID().uuidString,
            disasterType: input.disasterType,
            dangerZone: input.dangerZone,
            occurredAt: input.occurredAt,
            createdAt: .now
        )
    }

    func getDisaster(disasterId: String) async throws -> Disaster {
        guard let disaster = disasters.first(where: { $0.id == disasterId }) else {
            throw FirebaseRepositoryError.documentNotFound
        }
        return disaster
    }

    func updateDisaster(disasterId: String, input: CreateDisasterInput) async throws {}
    func deleteDisaster(disasterId: String) async throws {}
    func getDisasters(within bounds: MunicipalityBounds?) async throws -> [Disaster] {
        guard let bounds else { return disasters }
        return disasters.filter { disaster in
            disaster.dangerZone.contains { point in
                bounds.contains(
                    CLLocationCoordinate2D(latitude: point.latitude, longitude: point.longitude)
                )
            }
        }
    }
}
