//
//  DisasterRepository.swift
//  matiapu
//

import Foundation

protocol DisasterRepository: Sendable {
    func createDisaster(_ input: CreateDisasterInput) async throws -> Disaster
    func getDisaster(disasterId: String) async throws -> Disaster
    func updateDisaster(disasterId: String, input: CreateDisasterInput) async throws
    func deleteDisaster(disasterId: String) async throws
    func getDisasters(within bounds: MunicipalityBounds?) async throws -> [Disaster]
}
