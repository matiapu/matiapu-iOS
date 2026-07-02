//
//  ShelterRepository.swift
//  matiapu
//

import FirebaseFirestore
import Foundation

final class FirebaseShelterRepository: ShelterRepository, @unchecked Sendable {
    private let db = Firestore.firestore()

    func createShelter(_ input: CreateShelterInput) async throws -> Shelter {
        let documentRef = db.collection(FirestoreCollections.shelters).document()
        let payload: [String: Any] = [
            "shelter_name": input.shelterName,
            "location": GeoPoint(latitude: input.latitude, longitude: input.longitude),
            "capacity": input.capacity as Any,
        ]
        try await documentRef.setData(payload)
        return Shelter(
            id: documentRef.documentID,
            shelterName: input.shelterName,
            latitude: input.latitude,
            longitude: input.longitude,
            capacity: input.capacity,
            municipality: nil
        )
    }

    func getShelter(shelterId: String) async throws -> Shelter {
        let snapshot = try await db.collection(FirestoreCollections.shelters).document(shelterId).getDocument()
        guard let data = snapshot.data(), let shelter = mapShelter(id: snapshot.documentID, data: data) else {
            throw FirebaseRepositoryError.documentNotFound
        }
        return shelter
    }

    func updateShelter(shelterId: String, input: CreateShelterInput) async throws {
        try await db.collection(FirestoreCollections.shelters).document(shelterId).updateData([
            "shelter_name": input.shelterName,
            "location": GeoPoint(latitude: input.latitude, longitude: input.longitude),
            "capacity": input.capacity as Any,
        ])
    }

    func deleteShelter(shelterId: String) async throws {
        try await db.collection(FirestoreCollections.shelters).document(shelterId).delete()
    }

    func getShelters(municipality: String?) async throws -> [Shelter] {
        if let municipality, !municipality.isEmpty {
            let snapshot = try await db.collection(FirestoreCollections.shelters)
                .whereField("municipality", isEqualTo: municipality)
                .getDocuments()
            return snapshot.documents.compactMap { mapShelter(id: $0.documentID, data: $0.data()) }
        }

        let snapshot = try await db.collection(FirestoreCollections.shelters).getDocuments()
        return snapshot.documents.compactMap { mapShelter(id: $0.documentID, data: $0.data()) }
    }

    private func mapShelter(id: String, data: [String: Any]) -> Shelter? {
        guard
            let shelterName = data["shelter_name"] as? String,
            let location = data["location"] as? GeoPoint
        else {
            return nil
        }

        return Shelter(
            id: id,
            shelterName: shelterName,
            latitude: location.latitude,
            longitude: location.longitude,
            capacity: data["capacity"] as? Int,
            municipality: data["municipality"] as? String
        )
    }
}
