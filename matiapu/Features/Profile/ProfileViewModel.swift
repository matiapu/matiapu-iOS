//
//  ProfileViewModel.swift
//  matiapu
//

import Foundation
import Observation

@Observable
@MainActor
final class ProfileViewModel {
    private(set) var profile: UserProfile?

    private let authRepository: any AuthRepository

    init(authRepository: any AuthRepository) {
        self.authRepository = authRepository
    }

    func loadProfile() async {
        profile = try? await authRepository.fetchCurrentUser()
    }

    func signOut() {
        Task {
            try? await authRepository.signOut()
            profile = nil
        }
    }
}
