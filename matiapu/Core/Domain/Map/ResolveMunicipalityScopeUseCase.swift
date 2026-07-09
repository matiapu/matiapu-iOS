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
        let profile = (try? await authRepository.fetchCurrentUser())
            ?? authRepository.cachedCurrentUser()
        guard let profile else { return nil }

        let area = profile.registeredArea.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !area.isEmpty else { return nil }

        let municipalityName = MunicipalityStore.shared.resolveMunicipalityName(from: area) ?? area
        return await MapMunicipalityScopeResolver.resolve(name: municipalityName)
    }
}
