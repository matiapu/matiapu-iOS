//
//  ResolveMunicipalityScopeUseCase.swift
//  matiapu
//

import Foundation

struct ResolveMunicipalityScopeUseCase: Sendable {
    private let authRepository: any AuthRepository

    init(authRepository: any AuthRepository) {
        self.authRepository = authRepository
    }

    @MainActor
    func execute() async -> MapMunicipalityScope? {
        guard let profile = try? await authRepository.fetchCurrentUser() else { return nil }
        let area = profile.registeredArea.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !area.isEmpty else { return nil }
        return await MapMunicipalityScopeResolver.resolve(name: area)
    }
}
