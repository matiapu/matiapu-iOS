//
//  MockShelterRepository.swift
//  matiapu
//

import Foundation

final class MockShelterRepository: ShelterRepository, @unchecked Sendable {
    private let shelters: [Shelter] = [
        Shelter(
            id: "mock-shelter-1",
            shelterName: "新宿区役所",
            latitude: 35.6939,
            longitude: 139.7036,
            capacity: 500,
            municipality: PreviewMockRegion.municipalityName
        ),
        Shelter(
            id: "mock-shelter-2",
            shelterName: "新宿中央公園",
            latitude: 35.6915,
            longitude: 139.7058,
            capacity: 200,
            municipality: PreviewMockRegion.municipalityName
        ),
    ]

    func createShelter(_ input: CreateShelterInput) async throws -> Shelter {
        Shelter(
            id: UUID().uuidString,
            shelterName: input.shelterName,
            latitude: input.latitude,
            longitude: input.longitude,
            capacity: input.capacity,
            municipality: nil
        )
    }

    func getShelter(shelterId: String) async throws -> Shelter {
        guard let shelter = shelters.first(where: { $0.id == shelterId }) else {
            throw FirebaseRepositoryError.documentNotFound
        }
        return shelter
    }

    func updateShelter(shelterId: String, input: CreateShelterInput) async throws {}
    func deleteShelter(shelterId: String) async throws {}

    func getShelters(municipality: String?) async throws -> [Shelter] {
        MapMunicipalityFilter.shelters(shelters, municipality: municipality, boundary: nil)
    }
}
