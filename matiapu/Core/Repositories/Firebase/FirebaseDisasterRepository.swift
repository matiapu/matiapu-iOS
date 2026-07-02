//
//  DisasterRepository.swift
//  matiapu
//

import CoreLocation
import FirebaseFirestore
import Foundation

final class FirebaseDisasterRepository: DisasterRepository, @unchecked Sendable {
    private let db = Firestore.firestore()

    func createDisaster(_ input: CreateDisasterInput) async throws -> Disaster {
        let documentRef = db.collection(FirestoreCollections.disasters).document()
        let now = FirestoreDateCodec.timestamp()
        let payload: [String: Any] = [
            "disaster_type": input.disasterType.rawValue,
            "danger_zone": input.dangerZone.map { ["lat": $0.latitude, "lng": $0.longitude] },
            "occurred_at": FirestoreDateCodec.timestamp(from: input.occurredAt),
            "created_at": now,
        ]
        try await documentRef.setData(payload)
        return Disaster(
            id: documentRef.documentID,
            disasterType: input.disasterType,
            dangerZone: input.dangerZone,
            occurredAt: input.occurredAt,
            createdAt: .now
        )
    }

    func getDisaster(disasterId: String) async throws -> Disaster {
        let snapshot = try await db.collection(FirestoreCollections.disasters).document(disasterId).getDocument()
        guard let data = snapshot.data(), let disaster = mapDisaster(id: snapshot.documentID, data: data) else {
            throw FirebaseRepositoryError.documentNotFound
        }
        return disaster
    }

    func updateDisaster(disasterId: String, input: CreateDisasterInput) async throws {
        try await db.collection(FirestoreCollections.disasters).document(disasterId).updateData([
            "disaster_type": input.disasterType.rawValue,
            "danger_zone": input.dangerZone.map { ["lat": $0.latitude, "lng": $0.longitude] },
            "occurred_at": FirestoreDateCodec.timestamp(from: input.occurredAt),
        ])
    }

    func deleteDisaster(disasterId: String) async throws {
        try await db.collection(FirestoreCollections.disasters).document(disasterId).delete()
    }

    func getDisasters(within bounds: MunicipalityBounds?) async throws -> [Disaster] {
        let snapshot = try await db.collection(FirestoreCollections.disasters)
            .order(by: "occurred_at", descending: true)
            .getDocuments()
        let disasters = snapshot.documents.compactMap { mapDisaster(id: $0.documentID, data: $0.data()) }
        return disasters.filter { disaster in
            guard let bounds else { return true }
            return disaster.dangerZone.contains { point in
                bounds.contains(
                    CLLocationCoordinate2D(latitude: point.latitude, longitude: point.longitude)
                )
            }
        }
    }

    private func mapDisaster(id: String, data: [String: Any]) -> Disaster? {
        guard
            let typeRaw = data["disaster_type"] as? String,
            let disasterType = DisasterType(rawValue: typeRaw),
            let dangerZoneRaw = data["danger_zone"] as? [[String: Any]]
        else {
            return nil
        }

        let dangerZone = dangerZoneRaw.compactMap { point -> DangerZonePoint? in
            guard let lat = point["lat"] as? Double, let lng = point["lng"] as? Double else { return nil }
            return DangerZonePoint(latitude: lat, longitude: lng)
        }

        return Disaster(
            id: id,
            disasterType: disasterType,
            dangerZone: dangerZone,
            occurredAt: FirestoreDateCodec.date(from: data["occurred_at"]) ?? .now,
            createdAt: FirestoreDateCodec.date(from: data["created_at"]) ?? .now
        )
    }
}
