//
//  ShelterRepository.swift
//  matiapu
//

import Foundation

protocol ShelterRepository: Sendable {
    func createShelter(_ input: CreateShelterInput) async throws -> Shelter
    func getShelter(shelterId: String) async throws -> Shelter
    func updateShelter(shelterId: String, input: CreateShelterInput) async throws
    func deleteShelter(shelterId: String) async throws
    func getShelters(municipality: String?) async throws -> [Shelter]
}
